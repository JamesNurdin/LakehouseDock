WITH company_movies AS (
  SELECT
    cn.id AS company_id,
    cn.name AS company_name,
    ct.kind AS company_type,
    t.production_year,
    COUNT(DISTINCT t.id) AS movie_count
  FROM movie_companies mc
  JOIN company_name cn ON mc.company_id = cn.id
  JOIN company_type ct ON mc.company_type_id = ct.id
  JOIN title t ON mc.movie_id = t.id
  JOIN kind_type kt ON t.kind_id = kt.id
  WHERE kt.kind = 'movie'
    AND t.production_year IS NOT NULL
  GROUP BY cn.id, cn.name, ct.kind, t.production_year
), ranked_companies AS (
  SELECT
    company_id,
    company_name,
    company_type,
    production_year,
    movie_count,
    ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY movie_count DESC) AS rank_in_year
  FROM company_movies
)
SELECT
  company_id,
  company_name,
  company_type,
  production_year,
  movie_count,
  rank_in_year
FROM ranked_companies
WHERE rank_in_year <= 5
ORDER BY production_year DESC, rank_in_year
