WITH movie_metrics AS (
  SELECT
    t.id AS movie_id,
    t.title,
    t.production_year,
    kt.kind AS kind,
    COUNT(DISTINCT ci.person_id) AS cast_count,
    COUNT(DISTINCT mc.company_id) FILTER (WHERE ct.kind = 'production') AS production_company_count,
    COUNT(DISTINCT mk.keyword_id) AS keyword_count
  FROM title t
  LEFT JOIN kind_type kt ON t.kind_id = kt.id
  LEFT JOIN cast_info ci ON ci.movie_id = t.id
  LEFT JOIN movie_companies mc ON mc.movie_id = t.id
  LEFT JOIN company_type ct ON mc.company_type_id = ct.id
  LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
  WHERE t.production_year IS NOT NULL
  GROUP BY t.id, t.title, t.production_year, kt.kind
)
SELECT
  production_year,
  kind,
  COUNT(*) AS movie_count,
  AVG(cast_count) AS avg_cast_per_movie,
  AVG(production_company_count) AS avg_production_companies_per_movie,
  AVG(keyword_count) AS avg_keywords_per_movie
FROM movie_metrics
WHERE production_year >= 2000
GROUP BY production_year, kind
ORDER BY production_year DESC, movie_count DESC
