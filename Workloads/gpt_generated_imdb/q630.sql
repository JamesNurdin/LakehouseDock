WITH yearly_company_counts AS (
  SELECT
    title.production_year,
    kind_type.kind,
    company_name.id AS company_id,
    company_name.name AS company_name,
    COUNT(DISTINCT title.id) AS title_count
  FROM title
  JOIN kind_type ON title.kind_id = kind_type.id
  JOIN movie_companies ON movie_companies.movie_id = title.id
  JOIN company_name ON company_name.id = movie_companies.company_id
  JOIN company_type ON company_type.id = movie_companies.company_type_id
  WHERE company_type.kind = 'production company'
    AND title.production_year IS NOT NULL
    AND title.production_year BETWEEN 2000 AND 2020
  GROUP BY
    title.production_year,
    kind_type.kind,
    company_name.id,
    company_name.name
),
ranked_companies AS (
  SELECT
    production_year,
    kind,
    company_id,
    company_name,
    title_count,
    ROW_NUMBER() OVER (PARTITION BY production_year, kind ORDER BY title_count DESC) AS rank
  FROM yearly_company_counts
)
SELECT
  production_year,
  kind,
  company_id,
  company_name,
  title_count,
  rank
FROM ranked_companies
WHERE rank <= 3
ORDER BY production_year, kind, rank
