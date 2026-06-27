WITH company_movie_stats AS (
  SELECT
    ct.kind AS company_type,
    cn.id AS company_id,
    cn.name AS company_name,
    COUNT(DISTINCT t.id) AS movies_count,
    AVG(t.production_year) AS avg_production_year,
    COUNT(DISTINCT k.keyword) AS unique_keywords
  FROM movie_companies mc
  JOIN title t ON mc.movie_id = t.id
  JOIN kind_type kt ON t.kind_id = kt.id
  JOIN company_type ct ON mc.company_type_id = ct.id
  JOIN company_name cn ON mc.company_id = cn.id
  LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
  LEFT JOIN keyword k ON mk.keyword_id = k.id
  WHERE kt.kind = 'movie'
    AND t.production_year >= 2000
  GROUP BY ct.kind, cn.id, cn.name
),
ranked_companies AS (
  SELECT
    company_type,
    company_name,
    movies_count,
    avg_production_year,
    unique_keywords,
    ROW_NUMBER() OVER (PARTITION BY company_type ORDER BY movies_count DESC) AS rn
  FROM company_movie_stats
)
SELECT
  company_type,
  company_name,
  movies_count,
  avg_production_year,
  unique_keywords
FROM ranked_companies
WHERE rn = 1
ORDER BY movies_count DESC
