# Software Factory Dashboard - Tab 2: Visual Analytics
## Functional Specification

---

## Overview
- **Tab Name:** Visual Analytics
- **Purpose:** Display pipeline metrics in chart form for quick insights
- **Target Users:** Developers, leads, stakeholders wanting visual overview

---

## Charts Specification

### C1. Run Type Distribution (Pie Chart)
| Property | Value |
|----------|-------|
| Type | Donut/Pie chart |
| Data | Count by `runType` (FEATURE_BUILD, BUG_FIX, MAINTENANCE) |
| Colors | FEATURE_BUILD: Blue, BUG_FIX: Red, MAINTENANCE: Gray |
| Center | Total count |
| Interaction | Hover shows count + percentage |

### C2. T-Shirt Size Distribution (Pie Chart)
| Property | Value |
|----------|-------|
| Type | Donut chart |
| Data | Count by `tshirtSize` (XS, S, M, L, XL) |
| Colors | XS: Green, S: Blue, M: Yellow, L: Orange, XL: Red |
| Center | Total features |
| Insight | Shows feature size mix |

### C3. Time by Project (Horizontal Bar Chart)
| Property | Value |
|----------|-------|
| Type | Horizontal bar |
| Data | Total `actualDurationMinutes` by project |
| Sort | Descending by time |
| Labels | Project name + total hours |

### C4. Time by T-Shirt Size (Bar Chart)
| Property | Value |
|----------|-------|
| Type | Vertical bar |
| Data | Avg duration by `tshirtSize` |
| X-Axis | T-Shirt sizes (XS→XL) |
| Y-Axis | Average minutes |
| Insight | Shows sizing accuracy |

### C5. Success Rate by Project (Horizontal Bar)
| Property | Value |
|----------|-------|
| Type | Horizontal bar with % label |
| Data | Success count / total runs by project |
| Colors | Green (100%), Yellow (80-99%), Red (<80%) |
| Range | 0-100% |

### C6. Effort Breakdown (Stacked Bar)
| Property | Value |
|----------|-------|
| Type | Stacked horizontal bar |
| Data | `coderTimeMs` vs `testerTimeMs` by project |
| Colors | Coder: Blue, Tester: Green |
| Insight | Shows coding vs testing ratio |

### C7. Bugs by Severity (Pie Chart)
| Property | Value |
|----------|-------|
| Type | Donut chart |
| Data | Count by `severity` (low, medium, high, critical) |
| Colors | Low: Green, Medium: Yellow, High: Orange, Critical: Red |

### C8. Test Coverage (Pie Chart)
| Property | Value |
|----------|-------|
| Type | Donut chart |
| Data | `unitTestsPassed` vs `uatTestsPassed` |
| Colors | Unit: Blue, UAT: Purple |
| Center | Total tests passed |

### C9. Velocity Metrics (Gauge Cards)
| Metric | Type | Source |
|--------|------|--------|
| Avg Cycle Time | Gauge | Average `actualDurationMinutes` |
| Throughput | Number | Runs per week |
| Rework Rate | Gauge | `reopenedBugs` / total bugs |
| UAT Pass Rate | Gauge | UAT passed / total UAT |

### C10. Dependency Impact (Bar Chart)
| Property | Value |
|----------|-------|
| Type | Vertical bar |
| Data | Count of runs by `dependenciesAffected` |
| X-Axis | 1, 2, 3, 4+ deps |
| Y-Axis | Number of runs |

---

## Layout

```
┌─────────────────────────────────────────────────────────────┐
│  📊 Visual Analytics                    [Filters: Project▼] │
├─────────────────────────────────────────────────────────────┤
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐    │
│  │ Run Type │  │ T-Shirt  │  │  Tests   │  │ Severity │    │
│  │   Pie    │  │   Pie    │  │   Pie    │  │   Pie    │    │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘    │
│                                                             │
│  ┌─────────────────────────────────────┐  ┌──────────────┐ │
│  │     Time by Project (Bar)           │  │ Success Rate │ │
│  │     ████████████████████             │  │ ██████████   │ │
│  └─────────────────────────────────────┘  └──────────────┘ │
│                                                             │
│  ┌─────────────────────────────────────────────────────────┐│
│  │              Effort Breakdown (Stacked Bar)              ││
│  │  Project A  [███████░░░░░░] (Coder | Tester)           ││
│  │  Project B  [█████░░░░░░░░]                            ││
│  └─────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────┘
```

---

## Technical Implementation
- **Library:** Chart.js or Recharts
- **Data Source:** `/api/runs` filtered by project/time window
- **Responsive:** Stack charts on mobile
- **Animations:** Smooth transitions on data load

---

## Acceptance Criteria
- [ ] All 10 charts render correctly
- [ ] Filters apply to all charts
- [ ] Hover tooltips show detailed data
- [ ] Charts are readable on mobile
- [ ] Loading states shown during fetch
