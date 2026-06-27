WITH kind_title_stats AS (
  SELECT
    kt.kind,
    COUNT(t.id) AS title_count,
    AVG(t.production_year) AS avg_production_year
  FROM title t
  JOIN kind_type kt ON t.kind_id = kt.id
  GROUP BY kt.kind
),
kind_company_stats AS (
  SELECT
    kt.kind,
    COUNT(DISTINCT mc.company_id) AS distinct_company_count
  FROM title t
  JOIN kind_type kt ON t.kind_id = kt.id
  JOIN movie_companies mc ON mc.movie_id = t.id
  GROUP BY kt.kind
),
kind_info_type_stats AS (
  SELECT
    kt.kind,
    COUNT(DISTINCT it.info) AS distinct_info_type_count
  FROM title t
  JOIN kind_type kt ON t.kind_id = kt.id
  JOIN movie_info mi ON mi.movie_id = t.id
  JOIN info_type it ON mi.info_type_id = it.id
  GROUP BY kt.kind
),
keyword_counts AS (
  SELECT
    kt.kind,
    mk.keyword_id,
    COUNT(*) AS kw_count
  FROM title t
  JOIN kind_type kt ON t.kind_id = kt.id
  JOIN movie_keyword mk ON mk.movie_id = t.id
  GROUP BY kt.kind, mk.keyword_id
),
top_keyword_per_kind AS (
  SELECT
    kind,
    keyword_id,
    kw_count,
    ROW_NUMBER() OVER (PARTITION BY kind ORDER BY kw_count DESC) AS rn
  FROM keyword_counts
)
SELECT
  ks.kind,
  ks.title_count,
  ks.avg_production_year,
  cs.distinct_company_count,
  its.distinct_info_type_count,
  tk.keyword_id AS top_keyword_id,
  tk.kw_count AS top_keyword_count
FROM kind_title_stats ks
LEFT JOIN kind_company_stats cs ON ks.kind = cs.kind
LEFT JOIN kind_info_type_stats its ON ks.kind = its.kind
LEFT JOIN (
  SELECT kind, keyword_id, kw_count
  FROM top_keyword_per_kind
  WHERE rn = 1
) tk ON ks.kind = tk.kind
ORDER BY ks.title_count DESC
