WITH
  movie_actors AS (
    SELECT ci.movie_id,
           COUNT(DISTINCT ci.person_id) AS actor_count
    FROM cast_info ci
    GROUP BY ci.movie_id
  ),
  movie_keywords AS (
    SELECT mk.movie_id,
           COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    GROUP BY mk.movie_id
  ),
  movie_companies AS (
    SELECT mc.movie_id,
           COUNT(DISTINCT mc.company_id) AS company_count
    FROM movie_companies mc
    GROUP BY mc.movie_id
  )
SELECT
  kt.kind AS kind,
  t.production_year,
  COUNT(*) AS movie_count,
  AVG(COALESCE(ma.actor_count, 0)) AS avg_actors_per_movie,
  AVG(COALESCE(mk.keyword_count, 0)) AS avg_keywords_per_movie,
  AVG(COALESCE(mc.company_count, 0)) AS avg_companies_per_movie
FROM title t
LEFT JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN movie_actors ma ON t.id = ma.movie_id
LEFT JOIN movie_keywords mk ON t.id = mk.movie_id
LEFT JOIN movie_companies mc ON t.id = mc.movie_id
WHERE t.production_year IS NOT NULL
GROUP BY kt.kind, t.production_year
ORDER BY kt.kind, t.production_year
