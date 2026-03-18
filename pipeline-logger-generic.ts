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
  description?: string;
  version?: string;
  status: string;
  startedAt: string;
  completedAt: string;
  durationMs: number;
  architectTimeMs: number;
  coderTimeMs: number;
  testerTimeMs: number;
  testPassRate?: number;
  testsPassed?: number;
  testsFailed?: number;
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
    version: get('version'),
    status: get('status', 'SUCCESS'),
    description: get('description'),
    durationMs: parseInt(get('duration-ms', '0') || '0', 10),
    architectMs: parseInt(get('architect-ms', '0') || '0', 10),
    coderMs: parseInt(get('coder-ms', '0') || '0', 10),
    testerMs: parseInt(get('tester-ms', '0') || '0', 10),
    testsPassed: get('tests-passed') ? parseInt(get('tests-passed')!, 10) : undefined,
    testsFailed: get('tests-failed') ? parseInt(get('tests-failed')!, 10) : undefined,
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
    
    const completedAt = new Date();
    const startedAt = new Date(completedAt.getTime() - opts.durationMs);
    
    const run: PipelineRun = {
      id: `run-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`,
      projectId: opts.project || 'unknown',
      projectName: opts.project.split('-').map(w => w.charAt(0).toUpperCase() + w.slice(1)).join(' '),
      runType: opts.type,
      description: opts.description || undefined,
      version: opts.version || undefined,
      status: opts.status,
      startedAt: startedAt.toISOString(),
      completedAt: completedAt.toISOString(),
      durationMs: opts.durationMs,
      architectTimeMs: opts.architectMs,
      coderTimeMs: opts.coderMs,
      testerTimeMs: opts.testerMs,
      testPassRate,
      testsPassed: testsPassed || undefined,
      testsFailed: testsFailed || undefined,
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
