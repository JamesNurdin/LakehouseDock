WITH movie_stats AS (
  SELECT
    t.id AS movie_id,
    t.title,
    t.production_year,
    kt.kind AS kind,
    COUNT(DISTINCT ci.person_id) AS cast_count,
    COUNT(DISTINCT mc.company_id) AS company_count,
    slice(array_sort(array_agg(DISTINCT k.keyword)), 1, 3) AS top_keywords
  FROM title t
  LEFT JOIN kind_type kt
    ON t.kind_id = kt.id
  LEFT JOIN cast_info ci
    ON ci.movie_id = t.id
  LEFT JOIN movie_companies mc
    ON mc.movie_id = t.id
  LEFT JOIN movie_keyword mk
    ON mk.movie_id = t.id
  LEFT JOIN keyword k
    ON k.id = mk.keyword_id
  WHERE t.production_year BETWEEN 1990 AND 1999
  GROUP BY t.id, t.title, t.production_year, kt.kind
)
SELECT
  movie_id,
  title,
  production_year,
  kind,
  cast_count,
  company_count,
  top_keywords
FROM movie_stats
ORDER BY cast_count DESC, company_count DESC
LIMIT 20
