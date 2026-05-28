# AB Test Analysis - Filter Summary

**Purpose:** Ensure clean, valid Control vs Treatment comparison by filtering to the right users, events, and searches.

---

## What We're Measuring

### ✅ AB Test Participants Only

| Group | Size | Included? |
|-------|------|-----------|
| **Control (A)** | ~18,000 users | ✅ Yes |
| **Treatment (B)** | ~18,000 users | ✅ Yes |
| Non-participants (C) | ~1,770,000 users | ❌ No |

**Why:** We only want to compare users actually in the AB test.

---

### ✅ Search Events Only

**Included:**
- Search results displayed
- Shop clicked
- Pagination (viewing more results)
- Order completed

**Excluded:**
- Browsing restaurant lists
- Viewing favorites
- Non-search activity

**Why:** We're measuring search performance, not general browsing behavior.

---

### ✅ Post-Assignment Events Only

```
User assigned to Control → May 27, 9:00 AM
  ↓
Events BEFORE 9:00 AM → ❌ Excluded
Events AFTER 9:00 AM  → ✅ Included
```

**Why:** Only count events after users were assigned to prevent contamination.

---

### ✅ Relevant Search Tabs Only

| Search Tab | Description | Included? |
|------------|-------------|-----------|
| **ALL** | Mixed results (all vendor types) | ✅ Yes |
| **BAEMIN_DELIVERY** | Delivery-only results | ✅ Yes |
| NULL | Old Woowa browsing (not search) | ❌ No |
| BAEMIN_TAKEOUT | Pickup tab | ❌ No |

**Why:** AB test only covers ALL and DELIVERY tabs.

---

### ✅ Yesterday's Data Only

**Why yesterday?**
- AB test assignment data has a **1-day delay** (D+1 lag)
- Yesterday = most recent **complete** day of assignments
- Using today's data = incomplete/missing assignments = wrong results

---

### ✅ Minimum Volume (Detailed Query Only)

**Filter:** Each search term must have ≥5 searches in Treatment group

**Why:** Removes statistical noise from low-volume queries.

---

## Data Quality Checks

### Traffic Split Validation

**Expected:** ~50% Control, ~50% Treatment

**What we check:**
```
treatment_traffic_pct column in results
  ↓
Should show ~50.0%
  ↓
If <45% or >55% → Flag for investigation
```

---

### Statistical Significance

**We report:**
- CTR change (%)
- CVR change (%)
- **Is it statistically significant?** (Yes/No)

**Why:** A 5% improvement isn't meaningful if it's not statistically significant.

---

## Filter Chain (Simplified)

```
Start: 2 billion+ events/day
  ↓
Filter 1: Yesterday's search events only
  → 8 million events
  ↓
Filter 2: Users in AB test (A or B only)
  → 500K events
  ↓
Filter 3: Events after user was assigned
  → 400K events
  ↓
Filter 4: Has search tracking ID
  → 300-400 searches/day
  ↓
Filter 5: ALL or DELIVERY tabs only
  → 300-400 valid searches
  ↓
Result: Clean AB test sample
```

---

## What This Means

### ✅ Clean Comparison

**Control vs Treatment:**
- Same user types (app version ≥15.15)
- Same time period (yesterday)
- Same search tabs (ALL, DELIVERY)
- Same event types (search-related only)
- Events after assignment (no contamination)

### ✅ Accurate Results

**Because we:**
- Exclude non-participants (C group)
- Exclude pre-assignment events
- Exclude browsing activity
- Only measure actual searches
- Validate traffic split

### ✅ Statistical Validity

**We ensure:**
- ~50/50 traffic split
- Minimum volume thresholds
- Statistical significance testing
- Complete day of data (D+1 lag)

---

## Quick Reference

| Question | Answer |
|----------|--------|
| **Who?** | Users assigned to Control (A) or Treatment (B) only |
| **What?** | Search events with tracking IDs |
| **When?** | Events after assignment timestamp, yesterday's data |
| **Where?** | ALL and BAEMIN_DELIVERY tabs |
| **Why exclude C?** | They're not in the AB test |
| **Why yesterday only?** | Assignment data has D+1 lag |
| **How do we validate?** | Check ~50/50 traffic split in results |

---

## Red Flags to Watch For

🚩 **Traffic split not ~50/50**
- Could indicate assignment issues
- Check Eppo configuration

🚩 **Very low search volume**
- May need longer measurement period
- Or increase traffic % in AB test

🚩 **Statistical significance flip-flops**
- Could be noise from low volume
- Need more data before conclusions

---

**Last Updated:** May 28, 2026  
**For Technical Details:** See `AB_TEST_FILTERS_REFERENCE.md`
