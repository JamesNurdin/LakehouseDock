WITH movie_stats AS (
  SELECT
    t.id AS movie_id,
    t.title,
    t.production_year,
    COUNT(DISTINCT ci.person_id) AS cast_count,
    COUNT(DISTINCT mk.keyword_id) AS keyword_count,
    COUNT(DISTINCT mc.company_id) AS company_count
  FROM title t
  JOIN kind_type kt ON t.kind_id = kt.id
  LEFT JOIN cast_info ci ON ci.movie_id = t.id
  LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
  LEFT JOIN movie_companies mc ON mc.movie_id = t.id
  WHERE kt.kind = 'movie' AND t.production_year > 2000
  GROUP BY t.id, t.title, t.production_year
)
SELECT
  movie_id,
  title,
  production_year,
  cast_count,
  keyword_count,
  company_count,
  RANK() OVER (ORDER BY cast_count DESC) AS cast_rank,
  AVG(cast_count) OVER () AS avg_cast_count,
  PERCENT_RANK() OVER (ORDER BY cast_count DESC) AS cast_percentile
FROM movie_stats
ORDER BY cast_count DESC
LIMIT 10
