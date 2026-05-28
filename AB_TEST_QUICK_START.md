# AB Test Analysis Quick Start Guide

## When to Use AB Test Queries

Use AB test queries when:
- ✅ You want to compare **Control vs Treatment** variations during an active AB test
- ✅ You need **yesterday's data** (D+1 lag for assignments)
- ✅ You want to analyze **assigned users only** (exposure-gated)

Use Platform Comparison queries when:
- ✅ You want to compare **Woowa Search vs Global Search** platforms
- ✅ You need **multi-day trends** (7+ days)
- ✅ You want **historical analysis** before AB test launch

## Critical Requirement: D+1 Lag

**AB test queries MUST use yesterday's data** because:
- Eppo assignments have a **D+1 lag** (assignments from day N are available on day N+1)
- The assignment table is refreshed daily with previous day's data
- Using today's data will result in incomplete/missing assignments

```sql
-- ✅ CORRECT: Yesterday's data
DECLARE report_date DATE DEFAULT CURRENT_DATE() - 1;

-- ❌ WRONG: Today's data (incomplete assignments)
DECLARE report_date DATE DEFAULT CURRENT_DATE();
```

## Assignment Table Details

**Table:** `dhub-gd-analytics.eppo_input.gs_woowa_assignments`

**Source script:** `/Users/k.musina/Desktop/analytics/gs_woowa_eppo_assignments.sql`

**Key columns:**
- `assignment_user_id` — Perseus clientId (join key)
- `variation` — 'A' (Control), 'B' (Treatment), 'C' (Non-participants, excluded)
- `assignment_timestamp` — When user was assigned
- `assignment_date` — Date of assignment (partition key)
- `global_entity_id` — 'BM_KR'

**Variation Mapping:**
- **A = Control** (baseline, ~18K users, ~50% of AB test)
- **B = Treatment** (variant being tested, ~18K users, ~50% of AB test)
- **C = Non-participants** (~1.77M users, excluded from AB test analysis)

**Filters applied:**
- App version ≥15.15
- Exposure-gated (≥1 `shop_list.updated` post-assignment)
- First assignment wins (if multiple)

## Available AB Test Queries

All located in `woowa_search_analysis/`:

### 1. Overall Comparison (`overall_comparison_query_ab_test.sql`)
- **Output:** 2-3 rows (by search_vertical)
- **Use for:** Executive summary, daily check-ins
- **Runtime:** ~30-60 seconds
- **Shows:** Overall CTR/CVR/ZRR by vertical, traffic split

### 2. Head/Torso/Tail Comparison (`head_torso_tail_comparison_query_ab_test.sql`)
- **Output:** 6-9 rows (by vertical × tier)
- **Use for:** Strategic tier analysis
- **Runtime:** ~1-2 minutes
- **Shows:** Performance by query popularity tier (unified across variations)

### 3. Comprehensive Query-Level (`comprehensive_comparison_query_ab_test.sql`)
- **Output:** 100s-1000s rows (per search query)
- **Use for:** Deep dive, finding specific problem queries
- **Runtime:** ~2-5 minutes
- **Shows:** CTR/CVR per search term, statistical significance

## Join Logic Explained

```sql
-- Step 1: Get assignments (up to yesterday)
assignments AS (
  SELECT assignment_user_id AS client_id, variation, assignment_timestamp
  FROM `dhub-gd-analytics.eppo_input.gs_woowa_assignments`
  WHERE assignment_date <= report_date
    AND variation IN ('A', 'B')  -- A=Control, B=Treatment; exclude C=Non-participants
)

-- Step 2: Get Perseus events (yesterday only)
events AS (
  SELECT clientId AS client_id, eventTimestamp, ...
  FROM perseus.baemin_korea_perseus
  WHERE DATE(eventTimestamp) = report_date
)

-- Step 3: INNER JOIN + filter post-assignment events
assigned_events AS (
  SELECT e.*, a.variation
  FROM events e
  INNER JOIN assignments a
    ON e.client_id = a.client_id
  WHERE e.eventTimestamp >= a.assignment_timestamp  -- Critical!
)
```

**Why `eventTimestamp >= assignment_timestamp`?**
- Only count events **after** user was assigned to variation
- Prevents pre-assignment events from contaminating results
- Ensures clean Control vs Treatment comparison

## Traffic Split Validation

Expected: ~50/50 split between Control and Treatment

Check in query output:
```sql
treatment_traffic_pct  -- Should be ~50.0%
```

If imbalanced (>55% or <45%):
1. Query assignment table for variation counts
2. Check for platform/entity skew
3. Investigate Eppo configuration

## Common Mistakes to Avoid

❌ **Using today's data** → Incomplete assignments
```sql
DECLARE report_date DATE DEFAULT CURRENT_DATE();  -- WRONG
```

❌ **Using date ranges** → AB test queries use single date
```sql
DECLARE start_date DATE DEFAULT ...  -- WRONG (not in AB test queries)
```

❌ **Modifying the assignments CTE** → Pre-configured correctly
```sql
WHERE assignment_date = report_date  -- WRONG (should be <=)
```

❌ **Expecting NULL_VERTICAL** → Not in AB test scope
```sql
-- AB test only includes:
WHERE search_vertical IN ('ALL', 'BAEMIN_DELIVERY')
```

✅ **Correct usage:**
```sql
DECLARE report_date DATE DEFAULT CURRENT_DATE() - 1;  -- Yesterday
-- Use assignments CTE as-is (assignment_date <= report_date)
-- Only analyze ALL and BAEMIN_DELIVERY verticals
```

## Example Daily Workflow

```bash
# 1. Run overall check (quick)
bq query < woowa_search_analysis/overall_comparison_query_ab_test.sql

# 2. If issues found, drill into tiers
bq query < woowa_search_analysis/head_torso_tail_comparison_query_ab_test.sql

# 3. If specific queries problematic, go detailed
bq query < woowa_search_analysis/comprehensive_comparison_query_ab_test.sql
```

## Interpreting Results

### Good Signs ✅
- Treatment CTR > Control CTR with statistical significance
- Traffic split ~50/50
- Consistent improvement across verticals and tiers
- Head tier performing well (highest impact)

### Warning Signs ⚠️
- Traffic split significantly off 50/50
- Treatment regression in high-volume queries
- Inconsistent results across verticals
- Statistical significance for small effect sizes

### Red Flags 🚩
- Treatment significantly worse than Control
- Zero results rate increased
- Assignment count much lower than expected
- All queries showing "Insufficient Data"

## Need Help?

See full workflow documentation:
- `/Users/aybueke.kayaci/dh-pm-claude-skills/workflows/woowa-ab-test-analysis.md`

Or other docs in `woowa_search_analysis/`:
- `README.md` — Package overview
- `QUERY_COMPARISON.md` — When to use each query type
- `OVERALL_COMPARISON_GUIDE.md` — Overall query deep dive
- `HEAD_TORSO_TAIL_GUIDE.md` — Tier analysis guide
