# Head / Torso / Tail AB Test Query Guide

## 🎯 What This Query Does

This query breaks down AB test performance by **frequency tier** to understand how Control (A) vs Treatment (B) perform for different types of searches:

- **Head** (Top 50% of combined volume): Popular, high-volume search terms
- **Torso** (Next 30% of combined volume): Medium-popularity searches
- **Tail** (Bottom 20% of combined volume): Long-tail, rare searches

**Why this matters:** Head/Torso/Tail searches have different characteristics and require different optimization strategies. A treatment that wins overall might only win in Head tier, or vice versa.

**🔑 Key Feature:** Tiers are calculated based on **combined Control + Treatment volume**, ensuring the same queries are in the same tier for both variations (apples-to-apples comparison).

---

## 📊 Expected Output

You'll get **6-9 rows** (2-3 verticals × 3 tiers):

| search_vertical | frequency_tier | tier_definition | control_searches | control_unique_queries | control_cvr | treatment_searches | treatment_unique_queries | treatment_cvr | cvr_pct_change | cvr_stat_sig |
|-----------------|----------------|-----------------|------------------|------------------------|-------------|--------------------|--------------------------|--------------:|---------------:|--------------|
| ALL | Head | Top 50% of combined volume | 625,000 | 245 | 0.0520 | 640,000 | 245 | 0.0580 | **+11.54%** | ✅ Yes |
| ALL | Torso | Next 30% of combined volume | 312,500 | 680 | 0.0380 | 320,000 | 680 | 0.0420 | **+10.53%** | ✅ Yes |
| ALL | Tail | Bottom 20% of combined volume | 312,500 | 1,845 | 0.0180 | 320,000 | 1,845 | 0.0185 | **+2.78%** | ❌ No |
| BAEMIN_DELIVERY | Head | Top 50% of combined volume | 490,000 | 198 | 0.0495 | 500,000 | 198 | 0.0545 | **+10.10%** | ✅ Yes |
| ... | ... | ... | ... | ... | ... | ... | ... | ... | ... | ... |

---

## 🔑 Key Metrics by Tier

### Volume Distribution
- **`control_searches`** / **`treatment_searches`**: Total searches per variation in this tier
- **`control_unique_queries`** / **`treatment_unique_queries`**: Number of different search terms
- **Same query count:** Both variations should have the same unique_queries (unified tiers)

**Example:**
```
Head:  68% of volume, 245 unique terms, ~2,600 searches/term
Torso: 23% of volume, 680 unique terms, ~460 searches/term
Tail:   9% of volume, 1,845 unique terms, ~170 searches/term
```

### Performance Metrics
- **`control_ctr`** / **`treatment_ctr`**: Click-Through Rate by tier
- **`control_cvr`** / **`treatment_cvr`**: Conversion Rate by tier
- **`control_zrr`** / **`treatment_zrr`**: Zero Result Rate by tier

### Quality Metrics
- **`control_avg_click_rank`** / **`treatment_avg_click_rank`**: Average position clicked

### Comparison Metrics
- **`ctr_pct_change`** / **`cvr_pct_change`**: % difference Treatment vs Control
- **`ctr_stat_sig`** / **`cvr_stat_sig`**: Statistical significance

---

## 🎯 How to Interpret Results

### 1. Understanding Unified Tiers 🔄

**Important:** Tiers are calculated on **combined Control + Treatment volume**, not separately.

**Why this matters:**
```
❌ Old approach (separate tiers):
  Query "pizza": Head in Control, Torso in Treatment → Can't compare!

✅ New approach (unified tiers):
  Query "pizza": Head in both Control and Treatment → Fair comparison!
```

**Validation Check:**
- `control_unique_queries` should equal `treatment_unique_queries` for each tier
- If not equal → Bug in tier calculation

---

### 2. Typical Performance Patterns 📊

**Pattern 1: Head Tier Wins 🏆**
```
Head:   Control CVR 5.2%, Treatment CVR 5.8% (+11.5%, significant)
Torso:  Control CVR 3.8%, Treatment CVR 4.2% (+10.5%, significant)
Tail:   Control CVR 1.8%, Treatment CVR 1.9% (+2.8%, not significant)
```
**Interpretation:**
- Treatment wins across all tiers
- Head tier shows strongest improvement
- Tail improvement not statistically significant (expected - lower volume)

**Action:** Ship treatment - consistent wins, strongest in Head where volume matters most

---

**Pattern 2: Mixed Results ⚠️**
```
Head:   Control CVR 5.2%, Treatment CVR 5.6% (+7.7%, significant)
Torso:  Control CVR 3.8%, Treatment CVR 3.5% (-7.9%, significant) ← LOSING
Tail:   Control CVR 1.8%, Treatment CVR 1.9% (+5.6%, not significant)
```
**Interpretation:**
- Head tier wins
- Torso tier LOSES (significant degradation)
- Overall metric might be positive (Head volume > Torso volume)

**Action:** Investigate Torso tier losses before shipping
- Run detailed query filtered to Torso queries
- Understand what's different about Torso
- Consider shipping only for Head tier

---

**Pattern 3: Tail Tier Only Wins 🤔**
```
Head:   Control CVR 5.2%, Treatment CVR 5.0% (-3.8%, not significant)
Torso:  Control CVR 3.8%, Treatment CVR 3.7% (-2.6%, not significant)
Tail:   Control CVR 1.8%, Treatment CVR 2.5% (+38.9%, significant) ← WINNING
```
**Interpretation:**
- Tail tier shows massive improvement
- Head/Torso flat or slightly negative
- Overall metric might be negative (Head volume >> Tail volume)

**Action:** Investigate further
- Tail has low volume → high variance
- Check if Tail win is from a few queries or broad-based
- Probably not worth shipping if Head/Torso don't win

---

### 3. Volume vs Impact Trade-off ⚖️

**Key Insight:** Head tier has most volume, Tail tier has most queries

**Example:**
```
Head:  50% of searches, 245 queries   → High volume, low query diversity
Torso: 30% of searches, 680 queries   → Medium volume, medium diversity
Tail:  20% of searches, 1,845 queries → Low volume, high query diversity
```

**Optimization Priority:**
1. **Head tier** - Highest impact (50% of traffic)
2. **Torso tier** - Medium impact (30% of traffic)
3. **Tail tier** - Lowest impact (20% of traffic), but most queries

**Shipping Decision:**
- ✅ Ship if Head wins (drives 50% of traffic)
- 🤔 Reconsider if Head loses (even if Torso/Tail win)
- ⚠️ Don't ship if Head shows significant degradation

---

### 4. Statistical Significance by Tier 📉

**Expected Pattern:**
- Head tier: Usually significant (high volume)
- Torso tier: Sometimes significant (medium volume)
- Tail tier: Rarely significant (low volume)

**Why Tail might not be significant:**
```
Head:  625,000 searches → Enough for significance testing
Torso: 312,500 searches → Enough for significance testing
Tail:  312,500 searches BUT spread across 1,845 queries
       → ~170 searches/query → Often not enough per query
```

**Action:** Don't worry if Tail tier shows "not significant"
- Lower volume makes significance harder to achieve
- Focus on Head and Torso tiers for decision-making

---

## 🚨 Common Patterns & Actions

### Pattern 1: Consistent Win Across All Tiers ✅
```
Head:  +12% CVR (significant)
Torso: +8% CVR (significant)
Tail:  +5% CVR (not significant)
```
**Action:** Clear win - ship treatment immediately

---

### Pattern 2: Head Wins, Others Neutral 👍
```
Head:  +15% CVR (significant)
Torso: +2% CVR (not significant)
Tail:  -1% CVR (not significant)
```
**Action:** Ship treatment - Head drives majority of traffic

---

### Pattern 3: Head Loses, Torso/Tail Win ⚠️
```
Head:  -5% CVR (significant) ← PROBLEM
Torso: +8% CVR (significant)
Tail:  +12% CVR (not significant)
```
**Action:** DO NOT SHIP - Head tier degradation outweighs other wins
- Investigate why Head is losing
- Fix Head tier issues first

---

### Pattern 4: Torso Wins, Head/Tail Neutral 🤔
```
Head:  +1% CVR (not significant)
Torso: +15% CVR (significant) ← BIG WIN
Tail:  +3% CVR (not significant)
```
**Action:** Consider shipping - Torso represents 30% of traffic
- Validate Torso win is broad-based (not a few queries)
- Ensure Head doesn't show hidden degradation

---

## 💡 Next Steps After Tier Query

### If All Tiers Win:
1. ✅ Run **Detailed query** → Validate wins are broad-based, not driven by a few queries
2. ✅ Run **Query Classification** → Check if certain query types drive the win
3. ✅ Ship treatment confidently

### If Head Wins, Others Flat:
1. 👍 Run **Detailed query filtered to Head** → Which Head queries drive the win?
2. 👍 Ship treatment - Head is 50% of traffic

### If Mixed Results:
1. 🤔 Run **Detailed query** → Identify specific winning/losing queries
2. 🤔 Run **Query Classification** → See if pattern aligns with query types
3. 🤔 Investigate root cause of losses before shipping

### If Only Tail Wins:
1. ⚠️ Run **Detailed query filtered to Tail** → Is win from a few queries or broad-based?
2. ⚠️ Check if improvement is real or statistical noise (Tail has low volume)
3. ⚠️ Probably don't ship if Head/Torso don't improve

---

## 🎯 Optimization Strategy by Tier

### Head Tier (Top 50% volume)
**Characteristics:**
- High volume, popular queries
- Users know exactly what they want
- Examples: "pizza", "chicken", "burger"

**Optimization Focus:**
- Ranking quality (position 1-3 matters most)
- Speed (users expect instant results)
- Exact match positioning

**Success Metrics:**
- CVR improvement (orders matter)
- Click rank improvement (higher positions)
- Low zero result rate

---

### Torso Tier (Next 30% volume)
**Characteristics:**
- Medium volume, somewhat popular queries
- Mix of specific and exploratory intent
- Examples: "italian pasta", "spicy ramen"

**Optimization Focus:**
- Relevance (varied intents)
- Query understanding
- Result diversity

**Success Metrics:**
- CTR improvement (more relevant results)
- CVR improvement
- Lower pagination rate (find what they want on page 1)

---

### Tail Tier (Bottom 20% volume)
**Characteristics:**
- Low volume, rare/unique queries
- High variance in performance
- Examples: "gluten free vegan pizza near me"

**Optimization Focus:**
- Query expansion (handle unique queries)
- Fallback strategies (when exact match fails)
- Avoid zero results

**Success Metrics:**
- Zero result rate reduction
- CTR improvement (finding anything relevant)
- Don't degrade (hard to improve significantly)

---

## 📊 Example Analysis Workflow

**Step 1: Overall Query**
```sql
-- Run overall_comparison_query_ab_test.sql
-- Result: Treatment +7.78% CVR, significant
-- Question: Which tier drives this win?
```

**Step 2: Tier Breakdown**
```sql
-- Run head_torso_tail_comparison_query_ab_test.sql
-- Result:
--   Head:  +12% CVR (significant) ✅
--   Torso: +5% CVR (significant) ✅
--   Tail:  +2% CVR (not significant) ➖
```

**Step 3: Interpretation**
- Head tier drives the overall win (+12% CVR)
- Torso tier also wins (+5% CVR)
- Tail tier shows slight improvement but not significant (expected)
- **Conclusion:** Consistent win across important tiers

**Step 4: Validation**
```sql
-- Run comprehensive_comparison_query_ab_test.sql
-- Filter to Head tier queries
-- Validate: Are wins broad-based or driven by a few queries?
```

**Step 5: Decision**
- Head and Torso both win significantly → Ship treatment ✅

---

## 🔍 Advanced Analysis Tips

### 1. Check Query Count Consistency
```sql
-- Both variations should have SAME unique_queries per tier
SELECT frequency_tier, control_unique_queries, treatment_unique_queries
FROM results
WHERE control_unique_queries != treatment_unique_queries;
-- Should return 0 rows (if unified tiers work correctly)
```

### 2. Calculate Impact by Tier
```sql
-- Which tier contributes most to overall CVR improvement?
Tier Impact = (Tier % of volume) × (Tier CVR improvement)

Example:
Head:  50% volume × +12% CVR = 6.0% contribution
Torso: 30% volume × +5% CVR  = 1.5% contribution
Tail:  20% volume × +2% CVR  = 0.4% contribution
Total:                         7.9% overall improvement ✓
```

### 3. Look for Anti-Patterns
- ⚠️ Head losing + Overall winning → Torso/Tail can't compensate
- ⚠️ Huge Tail win + small volume → Likely noise, not real signal
- ⚠️ Different unique_queries count → Tier calculation bug

---

## 📅 Date Range

All queries use **fixed date range: May 30 - June 17, 2026 (inclusive)**

This ensures:
- ✅ Consistent tier definitions across analyses
- ✅ Reproducible results
- ✅ Fair comparison between Control and Treatment

---

## 🔗 Related Queries

- **`overall_comparison_query_ab_test.sql`** - High-level summary
- **`comprehensive_comparison_query_ab_test.sql`** - Drill down by specific query
- **`query_classification_breakdown_ab_test.sql`** - Drill down by classification
- **`exact_match_analysis_queries.sql`** - Restaurant query analysis

---

## 🎯 Key Takeaways

1. **Focus on Head tier** - Drives 50% of traffic, highest impact
2. **Unified tiers matter** - Ensures fair comparison between variations
3. **Don't ship if Head loses** - Even if Torso/Tail win
4. **Tail tier significance is rare** - Lower volume makes it harder
5. **Use this to find optimization opportunities** - Different tiers need different strategies
