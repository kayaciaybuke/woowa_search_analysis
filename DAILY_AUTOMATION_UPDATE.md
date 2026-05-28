# Daily Automation Update - May 27, 2026

## What Changed

### 1. ✅ Unified Volume-Based Tier Definitions (OPTION A)

**Old Approach (Fixed Thresholds, Separate per System):**
- Each system calculated its own tiers
- Head: ≥100 searches in that system
- Torso: 20-99 searches in that system
- Tail: <20 searches in that system
- **Problem:** Same query could be Head in Woowa, Torso in Global Search 😕

**New Approach (Unified Tiers, Combined Volume):**
- **Head**: Top 50% of **COMBINED** volume (Woowa + Global)
- **Torso**: Next 30% of **COMBINED** volume (50-80% cumulative)
- **Tail**: Bottom 20% of **COMBINED** volume (80-100% cumulative)
- **Benefit:** Same query in same tier for both systems ✅

**Why:** 
- Apples-to-apples comparison
- Same queries compared across both systems
- "pizza" is either Head in BOTH or Torso in BOTH
- More meaningful insights: "Global Search is +13% better on the SAME high-value queries"

**File Updated:** `head_torso_tail_comparison_query.sql`

**Full Explanation:** See `UNIFIED_TIERS_EXPLAINED.md`

---

### 2. ✅ Date Changed to CURRENT_DATE() (Today)

**Old:** `CURRENT_DATE() - 1` (Yesterday)

**New:** `CURRENT_DATE()` (Today)

**Why:** 
- Woowa is in Korea (UTC+9), ahead of most timezones
- When you run at 9am your time → Most of Woowa's day is done
- When you run at 5pm your time → Woowa's full day is complete
- "Today" gives you near-complete Woowa data

**Files Updated:**
- ✅ `overall_comparison_query.sql`
- ✅ `comprehensive_comparison_query.sql`
- ✅ `head_torso_tail_comparison_query.sql`
- ✅ `daily_alert_report_query.sql`

---

### 2. ✅ New Daily Alert Report Query

**What It Does:**
Automated daily monitoring that alerts you to:
1. Overall CVR/CTR changes (statistically significant)
2. Queries failing on Global Search (high ZRR, low CTR)
3. Session behavior changes (searches per session)
4. Top improving queries (celebrate wins!)
5. Top degrading queries (fix immediately)
6. NULL_VERTICAL performance (high-value segment)

**File Created:** `daily_alert_report_query.sql`

**Alert Levels:**
- 🔴 **CRITICAL**: CVR drop >10% (stat sig) OR ZRR >15%
- ⚠️ **WARNING**: CVR drop 5-10% OR ZRR >10% OR CTR <5%
- ✅ **POSITIVE**: CVR improvement >10% (stat sig)
- ℹ️ **INFO**: Normal performance

---

### 3. ✅ Comprehensive Daily Report Guide

**What It Contains:**
- How to read each alert section
- Alert priority matrix
- Response playbook for each alert type
- Tier definitions (updated to volume-based)
- Setup instructions for automation

**File Created:** `DAILY_REPORT_GUIDE.md`

---

## How to Use Daily Reports

### Quick Start (Manual)

Run the daily alert query in BigQuery:
```sql
-- Copy from: daily_alert_report_query.sql
-- It will analyze yesterday's data by default
-- Returns formatted alerts with severity levels
```

### Output Format

| report_date | section | detail | alert_message | alert_level |
|-------------|---------|--------|---------------|-------------|
| 2026-05-27 | OVERALL_SUMMARY | ALL | Global Search: 5,234 searches (37.2% of traffic), CTR: 11.2% (+14.5% ✓ sig)... | INFO |
| 2026-05-27 | FAILING_QUERIES | pizza | Query: "pizza" - 342 searches, CTR: 3.2%, ZRR: 22.0%... | WARNING |

### Filter by Alert Level

```sql
-- To see only critical issues:
WHERE alert_level = 'CRITICAL'

-- To see warnings and critical:
WHERE alert_level IN ('CRITICAL', 'WARNING')

-- To see wins:
WHERE alert_level = 'POSITIVE'
```

---

## Alert Examples

### Example 1: Good Day ✅
```
OVERALL_SUMMARY - ALL: Global Search improving
  CTR: 11.2% (+14.5% ✓ sig)
  CVR: 4.8% (+8.2% ✓ sig)
  Alert Level: POSITIVE

IMPROVING_QUERIES - korean bbq
  156 searches, CVR: 8.2% (+42.3% vs Woowa ✓ sig)
  Alert Level: POSITIVE
```
**Action:** Continue monitoring, document wins

### Example 2: Warning Day ⚠️
```
OVERALL_SUMMARY - DELIVERY: Global Search stable
  CTR: 9.8% (+3.2%)
  CVR: 4.1% (-6.8%)
  Alert Level: WARNING

FAILING_QUERIES - pizza
  342 searches, CTR: 3.2%, CVR: 1.1%, ZRR: 22.0%
  Alert Level: WARNING
```
**Action:** Investigate "pizza" query (high ZRR), check coverage

### Example 3: Critical Day 🔴
```
OVERALL_SUMMARY - ALL: Global Search degrading
  CVR: 2.8% (-18.4% ✓ sig)
  Alert Level: CRITICAL

DEGRADING_QUERIES - chicken
  2,340 searches, CVR: 1.9% (-32.1% vs Woowa ✓ sig)
  Alert Level: CRITICAL
```
**Action:** Escalate immediately, investigate top degrading queries

---

## What Monitoring is Looking For

### 1. Overall Metrics
- **CVR Changes**: Are conversions improving or degrading?
- **CTR Changes**: Are clicks improving?
- **Traffic Share**: What % goes to Global Search?
- **Statistical Significance**: Are changes real or random noise?

### 2. Query-Level Issues
- **High ZRR**: Queries returning no results (catalog problem)
- **Low CTR**: Poor ranking quality
- **CVR Drops**: Quality regressions vs Woowa Search

### 3. Session Behavior
- **Searches per session**: Increasing = users struggling, Decreasing = efficiency
- **Traffic changes**: Is Global Search getting more/less traffic?

### 4. NULL Vertical
- **High-value segment**: ~75% CVR (10x higher than normal)
- **Low volume but important**: Even small drops matter
- **Monitor closely**: Different user behavior

---

## Setting Up Automation

### Option 1: BigQuery Scheduled Query (Recommended)

1. Open `daily_alert_report_query.sql` in BigQuery Console
2. Click **"Schedule"** button
3. Configure:
   - **Schedule**: Every day at 9:00 AM KST
   - **Destination table**: `your_project.woowa_search.daily_alerts`
   - **Write preference**: Append (to keep history)
4. **Enable email notifications** for query failures
5. Done! Results append to table daily

### Option 2: Query Results Table + Data Studio

1. After setting up scheduled query (Option 1)
2. Create Data Studio dashboard:
   - Connect to `daily_alerts` table
   - Add filter for `alert_level`
   - Create charts for trending
   - Add tables for latest alerts
3. Share dashboard with stakeholders
4. Set up email alerts in Data Studio for CRITICAL alerts

### Option 3: Claude Skill (Coming Soon)

A Claude skill that:
- Runs the query automatically
- Formats results as readable report
- Sends daily email/Slack message
- Highlights critical issues at top

**Note:** Assignment table filtering not implemented yet - coming when AB test scales

---

## Files Added/Modified

### New Files:
1. ✅ `daily_alert_report_query.sql` - Main daily alert query
2. ✅ `DAILY_REPORT_GUIDE.md` - Comprehensive alert guide
3. ✅ `DAILY_AUTOMATION_UPDATE.md` - This file
4. ✅ `UNIFIED_TIERS_EXPLAINED.md` - Detailed explanation of unified tier approach
5. ✅ `head_torso_tail_comparison_query_OLD.sql` - Backup of old query

### Modified Files:
1. ✅ `head_torso_tail_comparison_query.sql` - Updated to unified volume-based tiers
2. ✅ `overall_comparison_query.sql` - Date changed to CURRENT_DATE()
3. ✅ `comprehensive_comparison_query.sql` - Date changed to CURRENT_DATE()
4. ✅ `daily_alert_report_query.sql` - Date changed to CURRENT_DATE()

### Unchanged Files:
- `overall_comparison_query.sql` - Still works as-is
- `comprehensive_comparison_query.sql` - Still works as-is
- All documentation files - Still accurate

---

## Next Steps

### Immediate (Today):
1. ✅ Test daily alert query manually in BigQuery
2. ✅ Verify output format and alerts
3. ✅ Review DAILY_REPORT_GUIDE.md

### This Week:
1. 📅 Set up BigQuery scheduled query (Option 1 above)
2. 📅 Create Data Studio dashboard (optional)
3. 📅 Run daily reports for 3-5 days to establish baseline
4. 📅 Document any alert patterns you observe

### Future (When Assignment Table Ready):
1. 🔮 Add assignment filtering to queries
2. 🔮 Filter to only ALL tab and DELIVERY tab for assigned users
3. 🔮 Measure test vs control lift
4. 🔮 Track assignment compliance

---

## Testing the Daily Report

### Run Manually First:
```sql
-- In BigQuery, run daily_alert_report_query.sql
-- Check output has these sections:
-- ✓ OVERALL_SUMMARY (3 rows - ALL, DELIVERY, NULL_VERTICAL)
-- ✓ FAILING_QUERIES (up to 10 rows)
-- ✓ IMPROVING_QUERIES (up to 5 rows)
-- ✓ DEGRADING_QUERIES (up to 10 rows)
-- ✓ SESSION_ANALYSIS (2 rows - Woowa Search, Global Search)
-- ✓ NULL_VERTICAL_ALERT (1 row if applicable)
```

### Expected Row Count:
- Minimum: ~8 rows (if no failing/improving/degrading queries)
- Typical: 20-30 rows
- Maximum: ~40 rows (if many issues found)

### Verify Alert Levels:
- CRITICAL: Should be rare (only for >10% CVR drops)
- WARNING: More common (ZRR >10%, CTR <5%, etc.)
- POSITIVE: Celebrate these!
- INFO: Most common

---

## FAQ

**Q: Why volume-based tiers instead of fixed thresholds?**
A: Ensures Head always represents the most impactful 50% of traffic, regardless of query count.

**Q: When will I get the first alert?**
A: After setting up scheduled query, first run happens next day at 9:00 AM.

**Q: Can I change the alert thresholds?**
A: Yes! Edit the CASE statements in `daily_alert_report_query.sql`

**Q: What if I get too many warnings?**
A: Adjust thresholds, or focus on CRITICAL alerts only during early test phase.

**Q: What about assignment table filtering?**
A: Not implemented yet. Will add when test scales and assignment data is available.

**Q: How do I track trends over time?**
A: Scheduled query appends to table daily. Query the table with date filters to see trends.

**Q: Can I get Slack/email notifications?**
A: Yes, via Data Studio alerts or custom Cloud Function (requires setup).

---

## Summary

**Before:**
- Manual query runs to check performance
- Fixed tier thresholds (≥100, 20-99, <20)
- No automated alerting

**After:**
- ✅ Automated daily monitoring
- ✅ Smart alert levels (CRITICAL/WARNING/POSITIVE/INFO)
- ✅ Volume-based tiers (Top 50%, Next 30%, Bottom 20%)
- ✅ Comprehensive guide for responding to alerts
- ✅ Query-level failure detection
- ✅ Session behavior tracking
- ✅ NULL vertical monitoring

**Impact:**
- Faster issue detection
- Prioritized action items
- Celebrate wins automatically
- Better understanding of test progress

---

Last Updated: May 27, 2026
