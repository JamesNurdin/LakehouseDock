WITH
  cast_counts AS (
    SELECT ci.movie_id AS movie_id,
           COUNT(DISTINCT ci.person_id) AS cast_count
    FROM cast_info ci
    GROUP BY ci.movie_id
  ),
  keyword_counts AS (
    SELECT mk.movie_id AS movie_id,
           COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    GROUP BY mk.movie_id
  ),
  budget_info AS (
    SELECT mi.movie_id AS movie_id,
           CAST(mi.info AS double) AS budget
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'budget'
  )
SELECT
  t.production_year,
  kt.kind,
  COUNT(*) AS movie_count,
  AVG(COALESCE(cc.cast_count, 0)) AS avg_cast_per_movie,
  AVG(COALESCE(kc.keyword_count, 0)) AS avg_keywords_per_movie,
  AVG(bi.budget) AS avg_budget
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN cast_counts cc ON cc.movie_id = t.id
LEFT JOIN keyword_counts kc ON kc.movie_id = t.id
LEFT JOIN budget_info bi ON bi.movie_id = t.id
WHERE t.production_year >= 2000
GROUP BY t.production_year, kt.kind
ORDER BY t.production_year DESC, movie_count DESC
