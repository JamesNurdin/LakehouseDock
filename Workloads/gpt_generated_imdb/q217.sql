WITH movies_by_company AS (
    SELECT
        cn.id AS company_id,
        cn.name AS company_name,
        cn.country_code,
        t.production_year,
        COUNT(DISTINCT mc.movie_id) AS movie_count
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    JOIN title t ON mc.movie_id = t.id
    WHERE ct.kind = 'production'
      AND t.production_year IS NOT NULL
    GROUP BY cn.id, cn.name, cn.country_code, t.production_year
),
ranked_companies AS (
    SELECT
        company_id,
        company_name,
        country_code,
        production_year,
        movie_count,
        RANK() OVER (PARTITION BY production_year ORDER BY movie_count DESC) AS rank_per_year
    FROM movies_by_company
)
SELECT
    company_id,
    company_name,
    country_code,
    production_year,
    movie_count,
    rank_per_year
FROM ranked_companies
WHERE rank_per_year <= 10
ORDER BY production_year, rank_per_year
