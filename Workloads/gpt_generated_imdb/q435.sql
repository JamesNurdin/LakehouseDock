WITH movies_by_type_year AS (
    SELECT
        ct.kind AS company_type,
        CAST(t.production_year AS integer) AS prod_year,
        COUNT(DISTINCT t.id) AS movie_count,
        COUNT(DISTINCT mc.company_id) AS distinct_company_count
    FROM movie_companies mc
    JOIN title t ON mc.movie_id = t.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    WHERE t.production_year IS NOT NULL
    GROUP BY ct.kind, CAST(t.production_year AS integer)
)
SELECT
    company_type,
    prod_year,
    movie_count,
    distinct_company_count,
    ROUND(movie_count * 100.0 / SUM(movie_count) OVER (PARTITION BY company_type), 2) AS pct_of_type
FROM movies_by_type_year
ORDER BY company_type, movie_count DESC
