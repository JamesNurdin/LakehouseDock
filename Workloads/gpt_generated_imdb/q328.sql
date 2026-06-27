SELECT
    company_type,
    decade,
    movie_count,
    avg_production_year,
    min_production_year,
    max_production_year,
    RANK() OVER (PARTITION BY company_type ORDER BY movie_count DESC) AS decade_rank
FROM (
    SELECT
        ct.kind AS company_type,
        (CAST(t.production_year AS integer) / 10) * 10 AS decade,
        COUNT(DISTINCT t.id) AS movie_count,
        AVG(t.production_year) AS avg_production_year,
        MIN(t.production_year) AS min_production_year,
        MAX(t.production_year) AS max_production_year
    FROM movie_companies mc
    JOIN title t ON mc.movie_id = t.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    WHERE t.production_year >= 1900
    GROUP BY ct.kind, (CAST(t.production_year AS integer) / 10) * 10
    HAVING COUNT(DISTINCT t.id) >= 5
) AS sub
ORDER BY company_type, decade_rank
