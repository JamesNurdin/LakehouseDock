WITH
  movie_keyword_counts AS (
    SELECT
      t.id AS movie_id,
      kt.id AS kind_id,
      COUNT(mk.keyword_id) AS keyword_count
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    GROUP BY t.id, kt.id
  ),
  movie_company_counts AS (
    SELECT
      t.id AS movie_id,
      kt.id AS kind_id,
      COUNT(DISTINCT mc.company_id) AS company_count
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN movie_companies mc ON mc.movie_id = t.id
    GROUP BY t.id, kt.id
  ),
  movie_info_counts AS (
    SELECT
      t.id AS movie_id,
      kt.id AS kind_id,
      COUNT(mi.info_type_id) AS info_count
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN movie_info mi ON mi.movie_id = t.id
    GROUP BY t.id, kt.id
  ),
  keyword_frequencies AS (
    SELECT
      kt.id AS kind_id,
      kw.keyword AS keyword,
      COUNT(*) AS keyword_occurrences
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    JOIN movie_keyword mk ON mk.movie_id = t.id
    JOIN keyword kw ON mk.keyword_id = kw.id
    GROUP BY kt.id, kw.keyword
  ),
  top_keyword_per_kind AS (
    SELECT
      kind_id,
      keyword,
      keyword_occurrences,
      ROW_NUMBER() OVER (PARTITION BY kind_id ORDER BY keyword_occurrences DESC) AS rn
    FROM keyword_frequencies
  ),
  aggregated_metrics AS (
    SELECT
      kc.kind_id,
      AVG(kc.keyword_count) AS avg_keyword_count,
      AVG(cc.company_count) AS avg_company_count,
      AVG(ic.info_count) AS avg_info_count
    FROM movie_keyword_counts kc
    JOIN movie_company_counts cc ON kc.movie_id = cc.movie_id AND kc.kind_id = cc.kind_id
    JOIN movie_info_counts ic ON kc.movie_id = ic.movie_id AND kc.kind_id = ic.kind_id
    GROUP BY kc.kind_id
  )
SELECT
  kt.kind AS kind,
  am.avg_keyword_count,
  am.avg_company_count,
  am.avg_info_count,
  tk.keyword AS top_keyword,
  tk.keyword_occurrences AS top_keyword_movie_count
FROM aggregated_metrics am
JOIN kind_type kt ON am.kind_id = kt.id
JOIN (
  SELECT kind_id, keyword, keyword_occurrences
  FROM top_keyword_per_kind
  WHERE rn = 1
) tk ON am.kind_id = tk.kind_id
ORDER BY kt.kind
