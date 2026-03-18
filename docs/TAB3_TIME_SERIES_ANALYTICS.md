# Software Factory Dashboard - Tab 3: Time Series Analytics
## Functional Specification

---

## Overview
- **Tab Name:** Trends
- **Purpose:** Track metrics over time to identify performance patterns
- **Target Users:** Leads tracking velocity, quality improvements over time
- **Time Filters:** Week, Month, Quarter, All (buttons)

---

## Time Filter Bar

| Button | Range | API Filter |
|--------|-------|------------|
| 📅 Week | Last 7 days | `?window=7` |
| 📅 Month | Last 30 days | `?window=30` |
| 📅 Quarter | Last 90 days | ``window=90` |
| 📅 All | All time | `?window=all` |

**UI:** Toggle button group, active state highlighted

---

## Charts Specification

### T1. Runs Over Time (Line Chart)
| Property | Value |
|----------|-------|
| Type | Line chart with area fill |
| X-Axis | Time (days/weeks depending on window) |
| Y-Axis | Number of runs |
| Lines | Total runs, Features, Bugs (toggleable) |
| Insight | Shows delivery velocity |

### T2. Throughput Trend (Line Chart)
| Property | Value |
|----------|-------|
| Type | Line chart |
| X-Axis | Week number |
| Y-Axis | Runs per week |
| Data | Rolling average (4-week) |
| Insight | Tracks improvement/decline |

### T3. Cycle Time Trend (Line Chart)
| Property | Value |
|----------|-------|
| Type | Line chart |
| X-Axis | Time |
| Y-Axis | Average duration (minutes) |
| Lines | Feature avg, Bug avg (toggleable) |
| Insight | Shows speed improvements |

### T4. Success Rate Trend (Line Chart)
| Property | Value |
|----------|-------|
| Type | Line chart |
| X-Axis | Time |
| Y-Axis | 0-100% |
| Threshold | Green line at 90% |
| Insight | Quality over time |

### T5. Test Pass Rate Trend (Line Chart)
| Property | Value |
|----------|-------|
| Type | Stacked area chart |
| X-Axis | Time |
| Y-Axis | Tests passed / failed |
| Areas | Unit passed, Unit failed, UAT passed, UAT failed |
| Insight | Quality breakdown over time |

### T6. Effort Over Time (Stacked Area)
| Property | Value |
|----------|-------|
| Type | Stacked area chart |
| X-Axis | Time |
| Y-Axis | Hours |
| Areas | Coding time, Testing time |
| Insight | Ratio of coding vs testing |

### T7. Features vs Bugs (Stacked Bar)
| Property | Value |
|----------|-------|
| Type | Stacked bar (weekly) |
| X-Axis | Week |
| Y-Axis | Count |
| Bars | Features (blue), Bugs (red) |
| Insight | Delivery vs maintenance ratio |

### T8. T-Shirt Accuracy (Line + Bar)
| Property | Value |
|----------|-------|
| Type | Combo chart |
| Bars | Estimated time |
| Line | Actual time |
| X-Axis | Each run |
| Insight | Estimation accuracy over time |

### T9. SF Utilization Over Time (Area Chart)
| Property | Value |
|----------|-------|
| Type | Area chart |
| X-Axis | Time |
| Y-Axis | % (0-100%) |
| Calculation | Total run time / total time in window |
| Insight | Factory uptime/efficiency |

### T10. Cumulative Delivery (Area Chart)
| Property | Value |
|----------|-------|
| Type | Cumulative area |
| X-Axis | Time |
| Y-Axis | Cumulative features delivered |
| Lines | Features, Bugs fixed |
| Insight | Total value delivered over time |

---

## Layout

```
┌─────────────────────────────────────────────────────────────┐
│  📈 Trends                    [Week][Month][Quarter][All]  │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │         Runs Over Time (Line)                        │   │
│  │    ████████████                                       │   │
│  │    ████████████████                                  │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌──────────────────────┐  ┌──────────────────────────┐   │
│  │  Cycle Time Trend   │  │    Success Rate Trend   │   │
│  │    (Line)           │  │      (Line)              │   │
│  └──────────────────────┘  └──────────────────────────┘   │
│                                                             │
│  ┌──────────────────────┐  ┌──────────────────────────┐   │
│  │   Effort Over Time  │  │   Features vs Bugs      │   │
│  │   (Stacked Area)    │  │     (Stacked Bar)       │   │
│  └──────────────────────┘  └──────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │         Cumulative Delivery (Area)                   │   │
│  │    Features: ████████████████████                   │   │
│  │    Bugs:     ████████████                          │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  📊 Summary: Last 30 days                                  │
│  • 12 runs completed                                       │
│  • 8 features, 4 bugs                                     │
│  • Avg cycle time: 12m (↓ 20%)                           │
│  • Success rate: 100%                                     │
└─────────────────────────────────────────────────────────────┘
```

---

## Time Window Logic

| Window | Data Points | X-Axis Format |
|--------|-------------|---------------|
| Week (7d) | Daily | Day (Mon, Tue...) |
| Month (30d) | Daily | Date (1, 2, 3...) |
| Quarter (90d) | Weekly | Week (W1, W2...) |
| All | Weekly/Monthly | Month (Jan, Feb...) |

---

## Summary Stats Bar

Below charts, show quick summary for selected window:

| Stat | Calculation |
|------|-------------|
| Total Runs | Count in window |
| Features | Count where type=FEATURE_BUILD |
| Avg Cycle Time | Average duration |
| Success Rate | Success / Total * 100 |
| Trend Arrow | Compare to previous period |

---

## Technical Implementation
- **Library:** Chart.js with time series plugin
- **Data Endpoint:** `/api/runs` with `?window=30` parameter
- **Caching:** Cache per-window for 5 minutes
- **Empty State:** "Not enough data for this time range"

---

## Acceptance Criteria
- [ ] Time filter buttons work and update all charts
- [ ] All 10 charts render with correct data
- [ ] X-axis scales appropriately per window
- [ ] Summary stats update with window
- [ ] Loading states shown during fetch
- [ ] Empty states handled gracefully
- [ ] Responsive on mobile
