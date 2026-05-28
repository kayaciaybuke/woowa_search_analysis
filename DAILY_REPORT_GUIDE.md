## Daily Alert Report Guide

Automated daily monitoring for Woowa Search vs Global Search performance.

## What Gets Monitored

### 1. Overall Summary (Every Vertical)
**Alert Levels:**
- 🔴 **CRITICAL**: CVR dropped >10% with statistical significance
- ⚠️ **WARNING**: CVR dropped 5-10% (stat sig) OR ZRR increased >20%
- ✅ **POSITIVE**: CVR improved >10% with statistical significance
- ℹ️ **INFO**: Normal performance, no significant issues

**What to look for:**
```
Global Search: 5,234 searches (37.2% of traffic), CTR: 11.2% (+14.5% ✓ sig), CVR: 4.8% (+8.2% ✓ sig), ZRR: 3.2%
```
- **Traffic share**: What % of searches go to Global Search
- **CTR change**: Is click rate improving? (✓ sig = statistically significant)
- **CVR change**: Is conversion rate improving?
- **ZRR**: Zero result rate (should be <5%)

### 2. Failing Queries on Global Search
**Alert Levels:**
- 🔴 **CRITICAL**: ZRR > 15% (many searches getting no results)
- ⚠️ **WARNING**: CTR < 5% OR ZRR > 10%
- ℹ️ **INFO**: Underperforming but not critical

**What to look for:**
```
Query: "pizza delivery" - 342 searches, CTR: 3.2% CVR: 1.1% ZRR: 22.0% (-35.2% vs Woowa)
```
- **High ZRR**: Catalog coverage issue - missing restaurants
- **Low CTR**: Ranking issue - relevant results not at top
- **CVR drop vs Woowa**: Quality regression

**Action:** Prioritize fixing queries with high search volume (>100/day) first

### 3. Top Improving Queries
**Alert Level:** ✅ **POSITIVE**

**What to look for:**
```
Query: "korean bbq" - 156 searches, CVR: 8.2% (+42.3% vs Woowa) ✓ sig
```
- Celebrate wins!
- Understand what's working (better ranking? better coverage?)
- Apply learnings to similar queries

### 4. Top Degrading Queries
**Alert Levels:**
- 🔴 **CRITICAL**: CVR dropped >20% with statistical significance
- ⚠️ **WARNING**: CVR dropped >10% with statistical significance

**What to look for:**
```
Query: "sushi near me" - 89 searches, CVR: 2.1% (-28.4% vs Woowa) ✓ sig
```
- **Action:** Investigate immediately if volume is high
- Possible causes:
  - Ranking changed (worse restaurants at top)
  - Missing key restaurants
  - Different search intent handling

### 5. Session Analysis
**Alert Level:** ℹ️ **INFO**

**What to look for:**
```
aws-search-woowa-cells-combined: 1,847 sessions, 2,456 searches, 1.33 searches/session
non-global-food-search: 4,892 sessions, 6,234 searches, 1.27 searches/session
```
- **Searches per session**: Lower is better (users find what they want faster)
- **Increasing trend**: Could indicate struggle OR high engagement
- **Decreasing trend**: Good if CTR/CVR are up (efficiency)

### 6. NULL Vertical Alert
**Alert Levels:**
- ⚠️ **WARNING**: CVR dropped >5% with statistical significance
- ℹ️ **INFO**: Otherwise

**Special consideration:**
- NULL vertical has exceptionally high CVR (~75%!)
- Represents high-value traffic segment
- Even small drops are worth investigating
- Low volume but high conversion impact

---

## Alert Priority Matrix

| Alert Level | Action | Timeline |
|-------------|--------|----------|
| 🔴 **CRITICAL** | Investigate immediately | Same day |
| ⚠️ **WARNING** | Review and monitor | Within 1-2 days |
| ✅ **POSITIVE** | Document wins, share learnings | Weekly summary |
| ℹ️ **INFO** | Track trends over time | No immediate action |

---

## How to Respond to Alerts

### CRITICAL: CVR Dropped >10%
1. **Check volume**: Is this high-traffic or low-traffic?
2. **Run detailed query**: Which specific search terms are causing the drop?
3. **Compare top results**: Did ranking change for key queries?
4. **Check for outages**: Any Global Search system issues?
5. **Escalate**: If high volume, escalate to search team immediately

### WARNING: High ZRR on Queries
1. **Check catalog coverage**: Are restaurants missing?
2. **Test query yourself**: What results do you see?
3. **Compare with Woowa**: What does old system show?
4. **Check filters**: Are filters too restrictive?
5. **Action**: Add missing restaurants OR adjust ranking

### WARNING: NULL Vertical CVR Drop
1. **Understand entry point**: How are NULL vertical users arriving?
2. **Check traffic source**: Is it coming from a specific feature?
3. **Compare user behavior**: Different patterns vs ALL/DELIVERY?
4. **Monitor closely**: This is high-value traffic

### POSITIVE: Big CVR Improvements
1. **Document what changed**: Ranking update? New feature?
2. **Identify pattern**: Which query types improved?
3. **Apply learnings**: Can we replicate this elsewhere?
4. **Share with team**: Celebrate wins

---

## Tier Definitions (Updated)

### Volume-Based Tiers:
- **Head**: Top 50% of search volume
  - Example: "pizza", "chicken", "sushi" (100+ searches/day)
  - Impact: Affects majority of users
  - Priority: Critical to optimize

- **Torso**: Next 30% of search volume (50-80%)
  - Example: "korean bbq", "ramen delivery" (20-99 searches/day)
  - Impact: Meaningful user base
  - Priority: High optimization opportunity

- **Tail**: Bottom 20% of search volume (80-100%)
  - Example: "gluten free pizza gangnam" (<20 searches/day)
  - Impact: Long-tail, diverse queries
  - Priority: Lower priority, focus on zero-result prevention

**Note:** Tier assignment is dynamic based on cumulative volume percentages, not fixed thresholds.

---

## Query Output Format

The daily report query returns rows in this format:

| report_date | section | detail | alert_message | alert_level |
|-------------|---------|--------|---------------|-------------|
| 2026-05-27 | OVERALL_SUMMARY | ALL | Global Search: 5,234 searches... | INFO |
| 2026-05-27 | FAILING_QUERIES | pizza | Query: "pizza" - 342 searches... | WARNING |
| 2026-05-27 | IMPROVING_QUERIES | korean bbq | Query: "korean bbq" - 156... | POSITIVE |

### Section Types:
1. **OVERALL_SUMMARY** - High-level metrics per vertical
2. **FAILING_QUERIES** - Top 10 queries with issues on Global Search
3. **IMPROVING_QUERIES** - Top 5 queries with biggest wins
4. **DEGRADING_QUERIES** - Top 10 queries with biggest drops
5. **SESSION_ANALYSIS** - Session-level behavior
6. **NULL_VERTICAL_ALERT** - NULL vertical performance (if applicable)

---

## Setting Up Daily Automation

### Option 1: BigQuery Scheduled Query
```sql
-- In BigQuery Console:
1. Open daily_alert_report_query.sql
2. Click "Schedule" button
3. Set schedule: Every day at 9:00 AM
4. Set destination table: your_project.your_dataset.daily_search_alerts
5. Enable email notifications for failures
```

### Option 2: Cloud Functions + Email
```python
# Cloud Function to run query and email results
# Triggers daily at 9:00 AM via Cloud Scheduler
# Sends formatted alert email with color-coded sections
```

### Option 3: Data Studio Dashboard
1. Create Data Studio report connected to scheduled query results table
2. Add filters for alert_level (CRITICAL, WARNING, POSITIVE)
3. Add time-series charts for trending
4. Share with stakeholders

---

## Reading the Report

### Good Day Example:
```
✅ OVERALL_SUMMARY - ALL: Global Search improving (+12.3% CVR ✓ sig)
✅ IMPROVING_QUERIES: 5 queries with significant wins
ℹ️ SESSION_ANALYSIS: Stable session behavior
```
**Action:** No immediate action, continue monitoring

### Warning Day Example:
```
⚠️ OVERALL_SUMMARY - DELIVERY: Global Search CVR -6.2% (not sig yet)
⚠️ FAILING_QUERIES: "pizza" - ZRR 18.3%
⚠️ FAILING_QUERIES: "sushi" - CTR 4.1%
```
**Action:** Investigate high-ZRR queries today

### Critical Day Example:
```
🔴 OVERALL_SUMMARY - ALL: Global Search CVR -15.8% ✓ sig
🔴 DEGRADING_QUERIES: "chicken" - 2,340 searches, CVR -32.1% ✓ sig
🔴 DEGRADING_QUERIES: "pizza" - 1,890 searches, CVR -28.4% ✓ sig
```
**Action:** Escalate immediately, investigate top queries

---

## Future Enhancements (Assignment Table)

When assignment table is ready:
- Filter to only assigned users (test group)
- Compare ALL tab searches vs DELIVERY tab for assigned users
- Track assignment compliance (did assigned users actually get Global Search?)
- Measure incremental lift (test vs control)

**Note:** Not implemented yet - will require additional filtering logic

---

## Tips

1. **Don't overreact to single-day drops** - Wait for 2-3 days to confirm trend
2. **Prioritize by volume** - Fix high-volume queries first (bigger impact)
3. **Track weekly trends** - Daily noise is expected, weekly trends matter
4. **Celebrate wins** - Share positive alerts with team for morale
5. **NULL vertical is special** - Monitor separately, different behavior
6. **Low Global Search volume** - Stats less reliable early in test, need patience

---

## Contact

For questions about the report:
- **What is being measured?** → Check this guide
- **Why is a metric changing?** → Run detailed query for specific search terms
- **How to fix issues?** → Coordinate with search/ranking team
- **Report bugs** → Check query logic in daily_alert_report_query.sql
