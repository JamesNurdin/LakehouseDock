WITH movie_data AS (
  SELECT
    t.id AS movie_id,
    t.kind_id,
    t.production_year
  FROM title t
  WHERE t.production_year IS NOT NULL
),
kw_stats AS (
  SELECT
    md.kind_id,
    COUNT(mk.keyword_id) AS total_kw_assignments,
    COUNT(DISTINCT mk.keyword_id) AS distinct_kw
  FROM movie_data md
  LEFT JOIN movie_keyword mk ON mk.movie_id = md.movie_id
  GROUP BY md.kind_id
),
comp_stats AS (
  SELECT
    md.kind_id,
    COUNT(mc.company_id) AS total_comp_assignments,
    COUNT(DISTINCT mc.company_id) AS distinct_comp
  FROM movie_data md
  LEFT JOIN movie_companies mc ON mc.movie_id = md.movie_id
  GROUP BY md.kind_id
),
movie_counts AS (
  SELECT
    md.kind_id,
    COUNT(*) AS total_movies,
    AVG(md.production_year) AS avg_production_year
  FROM movie_data md
  GROUP BY md.kind_id
)
SELECT
  kt.kind AS kind,
  mc.total_movies,
  mc.avg_production_year,
  ks.distinct_kw AS distinct_keywords,
  (ks.total_kw_assignments * 1.0) / mc.total_movies AS avg_keywords_per_movie,
  cs.distinct_comp AS distinct_companies,
  (cs.total_comp_assignments * 1.0) / mc.total_movies AS avg_companies_per_movie
FROM movie_counts mc
JOIN kind_type kt ON mc.kind_id = kt.id
LEFT JOIN kw_stats ks ON ks.kind_id = mc.kind_id
LEFT JOIN comp_stats cs ON cs.kind_id = mc.kind_id
ORDER BY mc.total_movies DESC
LIMIT 10
