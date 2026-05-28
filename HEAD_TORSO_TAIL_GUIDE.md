# Head / Torso / Tail Query Guide

## 🎯 What This Query Does

This query breaks down search performance by **frequency tier** to understand how different types of searches perform:

- **Head** (Top 50% of volume): Popular, high-volume search terms
- **Torso** (Next 30% of volume): Medium-popularity searches
- **Tail** (Bottom 20% of volume): Long-tail, rare searches

**Why this matters:** Head/Torso/Tail searches have different characteristics and require different optimization strategies.

**🆕 UPDATED:** Tiers are now **volume-based** (cumulative percentage) rather than fixed thresholds, ensuring Head always represents the most impactful searches.

---

## 📊 Expected Output

You'll get **9 rows** (3 verticals × 3 tiers):

| search_vertical | frequency_tier | tier_definition | woowa_search_searches | woowa_search_unique_search_terms | woowa_search_ctr | woowa_search_cvr | global_search_searches | global_search_ctr | global_search_cvr | ctr_pct_change |
|-----------------|----------------|-----------------|-------------|------------------------|--------|--------|--------------|---------|---------|----------------|
| ALL | Head | ≥100 searches | 85,340 | 245 | 0.1250 | 0.0520 | 62,150 | 0.1420 | 0.0580 | **+13.60%** |
| ALL | Torso | 20-99 searches | 28,450 | 680 | 0.0890 | 0.0380 | 19,200 | 0.1020 | 0.0420 | **+14.61%** |
| ALL | Tail | <20 searches | 11,550 | 1,845 | 0.0520 | 0.0180 | 7,900 | 0.0610 | 0.0210 | **+17.31%** |
| ... | ... | ... | ... | ... | ... | ... | ... | ... | ... | ... |

---

## 🔑 Key Metrics by Tier

### Volume Distribution
- **`woowa_search_pct_of_vertical_volume`**: What % of total searches this tier represents
- **`woowa_search_unique_search_terms`**: How many different search queries
- **`woowa_search_avg_searches_per_term`**: Average searches per unique term

**Example:**
```
Head:  68% of volume, 245 terms, 348 searches/term
Torso: 23% of volume, 680 terms, 42 searches/term
Tail:   9% of volume, 1,845 terms, 6 searches/term
```

### Performance Metrics
- **`woowa_search_ctr`** / **`global_search_ctr`**: Click-Through Rate by tier
- **`woowa_search_cvr`** / **`global_search_cvr`**: Conversion Rate by tier
- **`woowa_search_zrr`** / **`global_search_zrr`**: Zero Result Rate by tier

### Quality Metrics
- **`woowa_search_avg_click_rank`**: Average position clicked
- **`woowa_search_pct_clicks_pos_1`**: % of clicks on position 1
- **`woowa_search_avg_results`**: Average vendors shown

---

## 📈 Typical Performance Patterns

### Expected CTR by Tier:

| Tier | Expected CTR | Why |
|------|--------------|-----|
| **Head** | **Highest** (12-15%) | Users know what they want, clear intent |
| **Torso** | **Medium** (8-10%) | Moderate intent clarity |
| **Tail** | **Lowest** (4-6%) | Ambiguous, typos, rare items |

**⚠️ Warning:** If Tail CTR is higher than Head CTR, something is wrong!

---

### Expected ZRR by Tier:

| Tier | Expected ZRR | Why |
|------|--------------|-----|
| **Head** | **Lowest** (<3%) | Popular items, good coverage |
| **Torso** | **Medium** (3-8%) | Moderate coverage |
| **Tail** | **Highest** (>10%) | Rare/niche items, typos |

**💡 Insight:** High Tail ZRR is expected and acceptable.

---

## 🎯 Strategic Insights by Tier

### Head Searches (Top 50% of Volume)

**Characteristics:**
- 📊 Always 50% of total volume (by definition)
- 🎯 High intent, clear queries
- ✅ Should have highest CTR/CVR
- 💰 Highest revenue impact

**Optimization Priority:** **CRITICAL** ⭐⭐⭐
- Every 1% CTR improvement = massive impact
- These searches fund the business
- Must perform excellently
- **Dynamic**: Tier assignment adjusts as traffic patterns change

**Red Flags:**
- ❌ Head CTR lower than Torso/Tail
- ❌ High ZRR (>5%) in Head
- ❌ Avg click rank >3.0
- ❌ <50% clicks in top 3 positions

**Example Head Searches:**
- "pizza"
- "chicken"
- "burger"
- "sushi"

---

### Torso Searches (Next 30% of Volume)

**Characteristics:**
- 📊 Always 30% of total volume (by definition)
- 🎯 Moderate intent
- ✅ Good optimization opportunity
- 💰 Meaningful revenue contribution

**Optimization Priority:** **HIGH** ⭐⭐
- Underserved opportunity
- Easier wins than Head (less competitive)
- Can significantly improve overall metrics
- **Dynamic**: More queries than Head but each with lower individual volume

**Red Flags:**
- ❌ Torso CTR much lower than Head (>30% gap)
- ❌ High ZRR (>10%)
- ❌ Many Torso searches that should be Head

**Example Torso Searches:**
- "birthday cake delivery"
- "vegan pizza"
- "korean fried chicken"

---

### Tail Searches (Bottom 20% of Volume)

**Characteristics:**
- 📊 Always 20% of total volume (by definition)
- 🎯 Low/ambiguous intent
- ⚠️ Typos, rare items, exploratory
- 💰 Low individual impact
- **Very large number** of unique queries (long tail)

**Optimization Priority:** **LOW** ⭐
- Don't over-optimize
- Diminishing returns
- Focus on preventing zero results
- **Many queries**: Thousands of unique terms, each with very few searches

**Acceptable Performance:**
- ✅ Lower CTR is expected
- ✅ Higher ZRR is acceptable (10-20%)
- ✅ Some tail searches are noise

**Red Flags:**
- ❌ Tail volume >20% (too much noise)
- ❌ ZRR >30% (coverage issue)

**Example Tail Searches:**
- "spicy tofu pizza with extra cheese"
- "pizzza" (typo)
- "late night food near gangnam"

---

## 📊 Sample Output Analysis

### Example Results:

```
search_vertical: ALL

HEAD (≥100 searches):
- woowa_search_searches: 85,340 (68% of volume)
- woowa_search_unique_search_terms: 245
- woowa_search_ctr: 0.1250
- woowa_search_avg_click_rank: 2.1
- woowa_search_pct_clicks_pos_1: 52%

TORSO (20-99 searches):
- woowa_search_searches: 28,450 (23% of volume)
- woowa_search_unique_search_terms: 680
- woowa_search_ctr: 0.0890
- woowa_search_avg_click_rank: 3.2
- woowa_search_pct_clicks_pos_1: 38%

TAIL (<20 searches):
- woowa_search_searches: 11,550 (9% of volume)
- woowa_search_unique_search_terms: 1,845
- woowa_search_ctr: 0.0520
- woowa_search_avg_click_rank: 4.5
- woowa_search_pct_clicks_pos_1: 22%
```

### Interpretation:

✅ **Healthy Pattern:**
- Head has highest CTR (12.5%)
- Head has best click rank (2.1)
- Head has most clicks at #1 (52%)
- Volume distribution is reasonable (68/23/9)

📊 **Volume Distribution:**
- 245 Head terms drive 68% of searches = **348 searches/term average**
- 680 Torso terms drive 23% of searches = **42 searches/term average**
- 1,845 Tail terms drive 9% of searches = **6 searches/term average**

💡 **Strategic Focus:**
- **Priority 1:** Optimize those 245 Head terms (68% of volume!)
- **Priority 2:** Improve Torso CTR from 8.9% → closer to Head
- **Priority 3:** Don't worry too much about Tail

---

## 🚨 Red Flags to Watch For

### 1. Inverted Performance (CRITICAL)
```
Head CTR: 0.0650
Torso CTR: 0.0890  ← Higher than Head!
Tail CTR: 0.0520
```
**Problem:** Head searches should perform BEST, not worst!
**Action:** Investigate Head search quality immediately

---

### 2. Excessive Tail Volume
```
Head: 45% of volume
Torso: 30% of volume
Tail: 25% of volume  ← Too high!
```
**Problem:** Too many rare/low-quality searches
**Action:** Check for:
- Bot traffic
- Typos not being corrected
- Poor autocomplete

---

### 3. Head Zero Results
```
Head ZRR: 0.0850 (8.5%)  ← Too high!
```
**Problem:** Popular searches returning no results
**Action:** Catalog coverage issue - add missing items

---

### 4. Poor Torso Performance
```
Head CTR: 0.1200
Torso CTR: 0.0450  ← 62% lower!
```
**Problem:** Large performance gap
**Action:** Torso searches are underserved - big opportunity!

---

## 💡 Optimization Strategies by Tier

### Head Optimization:
1. **Ranking Quality:**
   - Top results must be perfect
   - Leverage click data (most signals)
   - Personalization opportunities

2. **Zero Results:**
   - Zero tolerance for ZRR
   - Add missing items immediately
   - Spell correction critical

3. **Merchandising:**
   - Curate top results manually if needed
   - Promoted placements
   - Seasonal adjustments

---

### Torso Optimization:
1. **Coverage:**
   - Ensure good vendor coverage
   - Reduce ZRR to <8%

2. **Ranking:**
   - Apply Head learnings
   - Semantic matching
   - Category-based ranking

3. **Discovery:**
   - Surface related items
   - "You might also like"

---

### Tail Optimization:
1. **Zero Results Prevention:**
   - Spell correction
   - Did you mean?
   - Fuzzy matching

2. **Fallbacks:**
   - Show popular items
   - Category fallbacks
   - Location-based suggestions

3. **Don't Over-Index:**
   - Accept lower CTR
   - Don't spend too much time here

---

## 📊 Comparison Insights

### Global Search vs Woowa Search by Tier:

**If Global Search improves all tiers equally:**
```
Head: +15% CTR
Torso: +14% CTR
Tail: +16% CTR
```
= **Across-the-board improvement** ✅

---

**If Global Search only improves Head:**
```
Head: +20% CTR
Torso: +2% CTR
Tail: -5% CTR
```
= **Optimized for popular searches** (valid strategy!)

---

**If Global Search only improves Tail:**
```
Head: +3% CTR
Torso: +5% CTR
Tail: +25% CTR
```
= **Wasting effort on low-impact searches** ⚠️

---

## 🎓 Advanced Analysis

### Calculate Volume Concentration:
```sql
-- What % of searches come from top N terms?
woowa_search_searches (Head) / total_searches = 68%
245 terms = 68% of volume

= High concentration (good!)
= Easy to optimize (focus on 245 terms)
```

### Calculate Long Tail Index:
```sql
Tail unique terms / Total unique terms
= 1,845 / (245 + 680 + 1,845)
= 67% of unique terms are Tail

But Tail is only 9% of volume
= Healthy long tail (not excessive)
```

---

## 📋 Recommended Actions

### Weekly:
1. Run this query to track tier performance
2. Monitor Head CTR (must stay high!)
3. Check Tail volume % (flag if >20%)

### Monthly:
1. Deep dive into Head searches (top 50)
2. Identify Torso → Head promotions
3. Analyze Tail → Torso graduates

### Quarterly:
1. Redefine tier thresholds if needed
2. Compare tier performance YoY
3. Adjust optimization priorities

---

## 🚀 Quick Start

```bash
# Copy query
pbcopy < ~/woowa_search_analysis/head_torso_tail_comparison_query.sql

# Run in BigQuery

# Expected output: 9 rows (3 verticals × 3 tiers)
```

---

## 💾 Export Tips

### For Reporting:
```
1. Export to Google Sheets
2. Create pivot: Vertical (rows) × Tier (columns)
3. Color code: Green (Head), Yellow (Torso), Red (Tail)
4. Add sparklines for trend tracking
```

### Key Viz:
- **Stacked bar:** Volume % by tier
- **Line chart:** CTR by tier over time
- **Scatter plot:** CTR vs Volume by tier

---

## 🔗 Related Queries

- **Overall Query**: High-level all searches
- **Detailed Query**: Per-search-term breakdown
- **This Query**: Aggregate by frequency tier

**Workflow:**
1. Overall → Is there an issue?
2. Head/Torso/Tail → Which tier has the issue?
3. Detailed → Which specific searches in that tier?

---

## 📅 Last Updated
May 27, 2026
