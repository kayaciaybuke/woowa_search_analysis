# Renaming Summary - May 27, 2026

## ✅ What Was Renamed

### Column Prefixes in Query Output:

| Old Name | New Name | Example |
|----------|----------|---------|
| `ng_` | `woowa_search_` | `ng_ctr` → `woowa_search_ctr` |
| `aws_` | `global_search_` | `aws_ctr` → `global_search_ctr` |

### Table Aliases in SQL:

| Old Alias | New Alias | Context |
|-----------|-----------|---------|
| `ng` | `woowa_search` | Table alias in FROM/JOIN clauses |
| `aws` | `global_search` | Table alias in FROM/JOIN clauses |

### Documentation Terms:

| Old Term | New Term |
|----------|----------|
| Non-Global (Food Search) | Woowa Search |
| AWS Cells / AWS cells combined | Global Search |

---

## 🔍 What Was NOT Changed

### Database Values (Preserved):
- `'non-global-food-search'` - Still used in WHERE clauses (actual DB value)
- `'aws-search-woowa-cells-combined'` - Still used in WHERE clauses (actual DB value)
- `account_id_group` field values remain unchanged

These are the actual values stored in the database and must remain as-is for queries to work.

---

## 📊 Example: Before vs After

### Before:
```sql
SELECT
  ng.searches AS ng_searches,
  ng.ctr AS ng_ctr,
  aws.searches AS aws_searches,
  aws.ctr AS aws_ctr,
  ROUND(SAFE_DIVIDE(aws.ctr - ng.ctr, NULLIF(ng.ctr, 0)) * 100, 2) AS ctr_pct_change
FROM
  (SELECT * FROM aggregated_metrics WHERE account_id_group = 'non-global-food-search') ng
FULL OUTER JOIN
  (SELECT * FROM aggregated_metrics WHERE account_id_group = 'aws-search-woowa-cells-combined') aws
  ON ng.search_vertical = aws.search_vertical;
```

### After:
```sql
SELECT
  woowa_search.searches AS woowa_search_searches,
  woowa_search.ctr AS woowa_search_ctr,
  global_search.searches AS global_search_searches,
  global_search.ctr AS global_search_ctr,
  ROUND(SAFE_DIVIDE(global_search.ctr - woowa_search.ctr, NULLIF(woowa_search.ctr, 0)) * 100, 2) AS ctr_pct_change
FROM
  (SELECT * FROM aggregated_metrics WHERE account_id_group = 'non-global-food-search') woowa_search
FULL OUTER JOIN
  (SELECT * FROM aggregated_metrics WHERE account_id_group = 'aws-search-woowa-cells-combined') global_search
  ON woowa_search.search_vertical = global_search.search_vertical;
```

---

## 📋 Files Updated

### SQL Files (3):
- ✅ `comprehensive_comparison_query.sql`
- ✅ `head_torso_tail_comparison_query.sql`
- ✅ `overall_comparison_query.sql`
- ⚪ `sample_perseus_data.sql` (no changes needed - exploration only)

### Documentation Files (8):
- ✅ `README.md`
- ✅ `QUERY_COMPARISON.md`
- ✅ `OVERALL_COMPARISON_GUIDE.md`
- ✅ `HEAD_TORSO_TAIL_GUIDE.md`
- ✅ `comprehensive_query_dimensions_guide.md`
- ✅ `query_output_columns_reference.md`
- ✅ `woowa_search_query_guide.md`
- ✅ `CHANGELOG.md`

---

## 🎯 Column Name Examples

### Overall Query Output:
| Column | Description |
|--------|-------------|
| `woowa_search_searches` | Total searches in Woowa Search |
| `woowa_search_ctr` | Click-Through Rate for Woowa Search |
| `woowa_search_cvr` | Conversion Rate for Woowa Search |
| `global_search_searches` | Total searches in Global Search |
| `global_search_ctr` | Click-Through Rate for Global Search |
| `global_search_cvr` | Conversion Rate for Global Search |
| `ctr_pct_change` | % change (Global Search vs Woowa Search) |

### Head/Torso/Tail Query Output:
| Column | Description |
|--------|-------------|
| `frequency_tier` | Head / Torso / Tail |
| `woowa_search_searches` | Total searches in Woowa Search for this tier |
| `woowa_search_ctr` | CTR for Woowa Search in this tier |
| `global_search_searches` | Total searches in Global Search for this tier |
| `global_search_ctr` | CTR for Global Search in this tier |

---

## ✅ Backwards Compatibility

**Breaking Change:** ⚠️ All column names have changed!

If you have:
- Existing reports referencing `ng_ctr` → Update to `woowa_search_ctr`
- Dashboards using `aws_cvr` → Update to `global_search_cvr`
- Sheets formulas with old names → Update column references

**Database queries remain compatible** - the actual WHERE clause values haven't changed.

---

## 🔧 How to Verify

Run this to check the renaming worked:

```bash
cd ~/woowa_search_analysis

# Check SQL files
echo "=== Checking SQL files for proper naming ==="
grep -c "woowa_search" *.sql
grep -c "global_search" *.sql

# Should find NO instances of old naming in column aliases
echo "=== Checking for old column prefixes (should be 0) ==="
grep -E "AS (ng|aws)_" *.sql | wc -l

# Check database values are preserved
echo "=== Checking database values are preserved ==="
grep "account_id_group = 'non-global-food-search'" *.sql
grep "account_id_group = 'aws-search-woowa-cells-combined'" *.sql
```

---

## 📅 Migration Date
May 27, 2026

## 🔄 Backup Location
All original files backed up in:
- `~/woowa_search_analysis/.backup/`

To restore original files if needed:
```bash
cp .backup/* .
```

---

## 💡 Why This Change?

**Clarity:** 
- "Woowa Search" is clearer than "Non-Global" or "ng"
- "Global Search" is clearer than "AWS Cells Combined" or "aws"

**Consistency:**
- Matches business terminology
- Easier for stakeholders to understand
- More intuitive column names in exports

**Professional:**
- Clean, descriptive naming
- Self-documenting queries
- Better for sharing with non-technical teams
