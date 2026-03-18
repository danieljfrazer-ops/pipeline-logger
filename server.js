/**
 * Pipeline Logger Server
 * Serves the dashboard and API for pipeline time tracking
 */

import express from 'express';
import cors from 'cors';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import fs from 'fs';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const app = express();
const PORT = process.env.PORT || 3010;
const LOG_FILE = process.env.PIPELINE_LOG_FILE || join(process.env.HOME || '/Users/danielfrazer', '.pipeline-runs.json');

// Middleware
app.use(cors());
app.use(express.json());

// Serve static dashboard
app.use(express.static(join(__dirname, 'dist')));

// API: Get all runs
app.get('/api/runs', (req, res) => {
  try {
    if (fs.existsSync(LOG_FILE)) {
      const data = fs.readFileSync(LOG_FILE, 'utf8');
      res.json(JSON.parse(data));
    } else {
      res.json([]);
    }
  } catch (e) {
    res.json([]);
  }
});

// API: Get summary stats
app.get('/api/summary', (req, res) => {
  try {
    if (!fs.existsSync(LOG_FILE)) {
      return res.json({ total: 0, projects: {} });
    }
    const data = JSON.parse(fs.readFileSync(LOG_FILE, 'utf8'));
    
    // Calculate summary
    const summary = {
      total: data.length,
      totalTime: data.reduce((sum, r) => sum + (r.durationMs || 0), 0),
      byProject: {},
      byType: {},
    };
    
    data.forEach((r) => {
      // By project
      if (!summary.byProject[r.projectId]) {
        summary.byProject[r.projectId] = { runs: 0, time: 0, success: 0, failed: 0 };
      }
      summary.byProject[r.projectId].runs++;
      summary.byProject[r.projectId].time += r.durationMs || 0;
      if (r.status === 'SUCCESS') summary.byProject[r.projectId].success++;
      else summary.byProject[r.projectId].failed++;
      
      // By type
      if (!summary.byType[r.runType]) {
        summary.byType[r.runType] = { runs: 0, time: 0 };
      }
      summary.byType[r.runType].runs++;
      summary.byType[r.runType].time += r.durationMs || 0;
    });
    
    res.json(summary);
  } catch (e) {
    res.json({ total: 0, projects: {}, error: e.message });
  }
});

// Catch-all for SPA
app.get('*', (req, res) => {
  res.sendFile(join(__dirname, 'dist', 'index.html'));
});

app.listen(PORT, () => {
  console.log(`Pipeline Logger running at http://localhost:${PORT}`);
});

export default app;
