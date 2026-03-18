/**
 * Generic Pipeline Logger
 * Works with any project - uses JSON file storage
 * 
 * Usage:
 *   npx tsx ~/projects/software-estimator/lib/pipeline-logger-generic.ts --project my-project --type FEATURE_BUILD --status SUCCESS --duration-ms 60000
 */

import fs from 'fs';
import path from 'path';

const LOG_FILE = process.env.PIPELINE_LOG_FILE || path.join(process.env.HOME || '/Users/danielfrazer', '.pipeline-runs.json');

interface PipelineRun {
  id: string;
  projectId: string;
  projectName: string;
  runType: string;
  tshirtSize?: 'XS' | 'S' | 'M' | 'L' | 'XL';
  severity?: 'low' | 'medium' | 'high' | 'critical';
  complexity?: number;
  description?: string;
  version?: string;
  status: string;
  startedAt: string;
  completedAt: string;
  durationMs: number;
  actualDurationMinutes?: number;
  // Effort breakdown (optional)
  architectTimeMs?: number;
  coderTimeMs?: number;
  testerTimeMs?: number;
  // Quality metrics
  testPassRate?: number;
  testsPassed?: number;
  testsFailed?: number;
  reopenedBugs?: number;
  // Additional
  dependenciesAffected?: number;
  apiChanges?: boolean;
  testCoverage?: number;
  createdAt: string;
}

function loadLog(): PipelineRun[] {
  try {
    if (fs.existsSync(LOG_FILE)) {
      return JSON.parse(fs.readFileSync(LOG_FILE, 'utf8'));
    }
  } catch (e) {
    console.error('Error loading log:', e);
  }
  return [];
}

function saveLog(runs: PipelineRun[]): void {
  fs.writeFileSync(LOG_FILE, JSON.stringify(runs, null, 2));
}

function parseArgs() {
  const args = process.argv.slice(2);
  const get = (name: string, defaultValue?: string): string => {
    const idx = args.indexOf(`--${name}`);
    return idx >= 0 && idx + 1 < args.length ? (args[idx + 1] || defaultValue || '') : (defaultValue || '');
  };
  
  return {
    project: get('project', 'unknown'),
    type: get('type', 'MAINTENANCE'),
    tshirtSize: get('tshirt-size'),
    severity: get('severity'),
    complexity: get('complexity') ? parseInt(get('complexity'), 10) : undefined,
    version: get('version'),
    status: get('status', 'SUCCESS'),
    description: get('description'),
    durationMs: parseInt(get('duration-ms', '0') || '0', 10),
    startedAt: get('started-at'),
    completedAt: get('completed-at'),
    architectMs: parseInt(get('architect-ms', '0') || '0', 10),
    coderMs: parseInt(get('coder-ms', '0') || '0', 10),
    testerMs: parseInt(get('tester-ms', '0') || '0', 10),
    testsPassed: get('tests-passed') ? parseInt(get('tests-passed')!, 10) : undefined,
    testsFailed: get('tests-failed') ? parseInt(get('tests-failed')!, 10) : undefined,
    reopenedBugs: get('reopened-bugs') ? parseInt(get('reopened-bugs')!, 10) : undefined,
    dependenciesAffected: get('deps') ? parseInt(get('deps')!, 10) : undefined,
    apiChanges: get('api-changes') === 'true' ? true : get('api-changes') === 'false' ? false : undefined,
    testCoverage: get('test-coverage') ? parseInt(get('test-coverage')!, 10) : undefined,
    action: get('action', 'log'),
  };
}

async function main() {
  const opts = parseArgs();
  
  if (opts.action === 'log') {
    const testsPassed = opts.testsPassed ?? 0;
    const testsFailed = opts.testsFailed ?? 0;
    const testPassRate = (testsPassed + testsFailed) > 0 
      ? Math.round((testsPassed / (testsPassed + testsFailed)) * 100)
      : undefined;
    
    // Calculate timestamps: use provided ISO times, or calculate from duration
    let startedAt: Date;
    let completedAt: Date;
    let durationMs: number;
    
    if (opts.startedAt && opts.completedAt) {
      // Auto-capture mode: use actual timestamps
      startedAt = new Date(opts.startedAt);
      completedAt = new Date(opts.completedAt);
      durationMs = completedAt.getTime() - startedAt.getTime();
    } else {
      // Legacy mode: calculate from duration
      completedAt = new Date();
      startedAt = new Date(completedAt.getTime() - opts.durationMs);
      durationMs = opts.durationMs;
    }
    
    const run: PipelineRun = {
      id: `run-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`,
      projectId: opts.project || 'unknown',
      projectName: opts.project.split('-').map(w => w.charAt(0).toUpperCase() + w.slice(1)).join(' '),
      runType: opts.type,
      tshirtSize: opts.tshirtSize as any,
      severity: opts.severity as any,
      complexity: opts.complexity,
      description: opts.description || undefined,
      version: opts.version || undefined,
      status: opts.status,
      startedAt: startedAt.toISOString(),
      completedAt: completedAt.toISOString(),
      durationMs: durationMs,
      architectTimeMs: opts.architectMs || 0,
      coderTimeMs: opts.coderMs || 0,
      testerTimeMs: opts.testerMs || 0,
      testPassRate,
      testsPassed: testsPassed || undefined,
      testsFailed: testsFailed || undefined,
      reopenedBugs: opts.reopenedBugs,
      dependenciesAffected: opts.dependenciesAffected,
      apiChanges: opts.apiChanges,
      testCoverage: opts.testCoverage,
      createdAt: new Date().toISOString(),
    };
    
    const runs = loadLog();
    runs.push(run);
    saveLog(runs);
    
    console.log(`✅ Logged: ${run.projectName} - ${run.runType} (${Math.round(run.durationMs / 60000)}m)`);
    console.log(`   Status: ${run.status}`);
    console.log(`   Log file: ${LOG_FILE}`);
  } 
  else if (opts.action === 'report') {
    const runs = loadLog();
    const days = parseInt(opts.project, 10) || 30; // default 30 days
    
    const cutoff = new Date();
    cutoff.setDate(cutoff.getDate() - days);
    
    const filtered = runs.filter(r => new Date(r.startedAt) >= cutoff);
    
    // Group by project
    const byProject: Record<string, PipelineRun[]> = {};
    filtered.forEach(r => {
      if (!byProject[r.projectId]) byProject[r.projectId] = [];
      byProject[r.projectId].push(r);
    });
    
    console.log(`\n📊 Pipeline Report (last ${days} days)\n`);
    console.log(`Total runs: ${filtered.length}`);
    console.log(`Log file: ${LOG_FILE}\n`);
    
    for (const [project, projectRuns] of Object.entries(byProject)) {
      const totalTime = projectRuns.reduce((sum, r) => sum + r.durationMs, 0);
      const success = projectRuns.filter(r => r.status === 'SUCCESS').length;
      
      console.log(`\n${project}:`);
      console.log(`  Runs: ${projectRuns.length}`);
      console.log(`  Time: ${Math.round(totalTime / 3600000 * 10) / 10}h`);
      console.log(`  Success: ${Math.round(success / projectRuns.length * 100)}%`);
    }
  }
  else if (opts.action === 'clear') {
    saveLog([]);
    console.log('✅ Log cleared');
  }
}

main().catch(console.error);
