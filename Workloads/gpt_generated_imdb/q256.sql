WITH movie_cast AS (
  SELECT t.id AS movie_id,
         t.title,
         t.production_year,
         kt.kind,
         COUNT(DISTINCT ci.person_id) AS cast_count,
         COUNT(DISTINCT ci.person_role_id) AS role_count,
         COUNT(DISTINCT CASE WHEN n.gender = 'F' THEN ci.person_id END) AS female_cast_count,
         COUNT(DISTINCT CASE WHEN n.gender = 'M' THEN ci.person_id END) AS male_cast_count
  FROM title t
  JOIN kind_type kt ON t.kind_id = kt.id
  LEFT JOIN cast_info ci ON ci.movie_id = t.id
  LEFT JOIN name n ON ci.person_id = n.id
  GROUP BY t.id, t.title, t.production_year, kt.kind
),
movie_keywords AS (
  SELECT mk.movie_id,
         COUNT(DISTINCT mk.keyword_id) AS keyword_count
  FROM movie_keyword mk
  GROUP BY mk.movie_id
),
movie_runtime AS (
  SELECT mi.movie_id,
         CAST(mi.info AS integer) AS runtime_minutes
  FROM movie_info mi
  JOIN info_type it ON mi.info_type_id = it.id
  WHERE lower(it.info) = 'runtime'
)
SELECT mc.production_year,
       mc.kind,
       COUNT(*) AS movie_count,
       AVG(mc.cast_count) AS avg_cast_per_movie,
       AVG(mc.role_count) AS avg_roles_per_movie,
       AVG(COALESCE(mk.keyword_count, 0)) AS avg_keywords_per_movie,
       AVG(rt.runtime_minutes) AS avg_runtime_minutes,
       AVG(mc.female_cast_count) AS avg_female_cast_per_movie,
       AVG(mc.male_cast_count) AS avg_male_cast_per_movie
FROM movie_cast mc
LEFT JOIN movie_keywords mk ON mk.movie_id = mc.movie_id
LEFT JOIN movie_runtime rt ON rt.movie_id = mc.movie_id
WHERE mc.production_year IS NOT NULL
GROUP BY mc.production_year, mc.kind
ORDER BY mc.production_year DESC, mc.kind
