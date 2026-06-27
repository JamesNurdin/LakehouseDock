WITH movies_by_company AS (
    SELECT
        t.production_year,
        cn.name,
        COUNT(DISTINCT t.id) AS movie_count
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    JOIN movie_companies mc ON mc.movie_id = t.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    JOIN company_name cn ON mc.company_id = cn.id
    WHERE ct.kind = 'production'
      AND kt.kind = 'movie'
      AND t.production_year >= 2000
    GROUP BY t.production_year, cn.name
),
ranked_companies AS (
    SELECT
        production_year,
        name,
        movie_count,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY movie_count DESC) AS rank_in_year
    FROM movies_by_company
)
SELECT
    production_year,
    name AS company_name,
    movie_count,
    rank_in_year
FROM ranked_companies
WHERE rank_in_year <= 10
ORDER BY production_year DESC, rank_in_year
