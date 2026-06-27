WITH cast_counts AS (
  SELECT
    cast_info.movie_id AS movie_id,
    COUNT(DISTINCT cast_info.person_id) AS cast_member_count
  FROM cast_info
  GROUP BY cast_info.movie_id
),
company_counts AS (
  SELECT
    movie_companies.movie_id AS movie_id,
    COUNT(DISTINCT movie_companies.company_id) AS company_count
  FROM movie_companies
  GROUP BY movie_companies.movie_id
),
keyword_counts AS (
  SELECT
    movie_keyword.movie_id AS movie_id,
    COUNT(DISTINCT movie_keyword.keyword_id) AS keyword_count
  FROM movie_keyword
  GROUP BY movie_keyword.movie_id
)
SELECT
  kind_type.kind AS kind,
  title.production_year AS production_year,
  COUNT(DISTINCT title.id) AS movie_count,
  AVG(cast_counts.cast_member_count) AS avg_cast_per_movie,
  AVG(company_counts.company_count) AS avg_companies_per_movie,
  AVG(keyword_counts.keyword_count) AS avg_keywords_per_movie
FROM title
JOIN kind_type
  ON title.kind_id = kind_type.id
LEFT JOIN cast_counts
  ON cast_counts.movie_id = title.id
LEFT JOIN company_counts
  ON company_counts.movie_id = title.id
LEFT JOIN keyword_counts
  ON keyword_counts.movie_id = title.id
WHERE title.production_year IS NOT NULL
GROUP BY kind_type.kind, title.production_year
ORDER BY kind_type.kind, title.production_year
