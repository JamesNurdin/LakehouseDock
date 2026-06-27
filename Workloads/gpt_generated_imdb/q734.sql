WITH cast_per_movie AS (
  SELECT
    t.id AS movie_id,
    t.production_year,
    kt.kind AS kind,
    COUNT(DISTINCT ci.person_id) AS cast_count
  FROM title t
  JOIN kind_type kt ON t.kind_id = kt.id
  LEFT JOIN cast_info ci ON ci.movie_id = t.id
  GROUP BY t.id, t.production_year, kt.kind
),
runtime_per_movie AS (
  SELECT
    t.id AS movie_id,
    AVG(try_cast(mi.info AS double)) AS avg_runtime
  FROM title t
  LEFT JOIN movie_info mi ON mi.movie_id = t.id
  LEFT JOIN info_type it ON mi.info_type_id = it.id
  WHERE it.info = 'runtime'
  GROUP BY t.id
)
SELECT
  cp.production_year,
  cp.kind,
  COUNT(DISTINCT cp.movie_id) AS total_movies,
  AVG(cp.cast_count) AS avg_cast_per_movie,
  COUNT(DISTINCT mc.company_id) AS total_distinct_companies,
  AVG(rp.avg_runtime) AS avg_runtime_minutes,
  COUNT(DISTINCT mk.keyword_id) AS total_distinct_keywords
FROM cast_per_movie cp
LEFT JOIN movie_companies mc ON mc.movie_id = cp.movie_id
LEFT JOIN movie_keyword mk ON mk.movie_id = cp.movie_id
LEFT JOIN runtime_per_movie rp ON rp.movie_id = cp.movie_id
GROUP BY cp.production_year, cp.kind
ORDER BY cp.production_year DESC, total_movies DESC
