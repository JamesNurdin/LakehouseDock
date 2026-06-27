WITH company_movie_stats AS (
    SELECT
        cn.id AS company_id,
        cn.name AS company_name,
        ct.kind AS company_type,
        COUNT(DISTINCT mc.movie_id) AS movie_count,
        AVG(t.production_year) AS avg_production_year,
        MIN(t.production_year) AS earliest_year,
        MAX(t.production_year) AS latest_year
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    JOIN title t ON mc.movie_id = t.id
    WHERE t.production_year >= 2000
    GROUP BY cn.id, cn.name, ct.kind
)
SELECT
    company_id,
    company_name,
    company_type,
    movie_count,
    avg_production_year,
    earliest_year,
    latest_year,
    RANK() OVER (PARTITION BY company_type ORDER BY movie_count DESC) AS rank_within_type
FROM company_movie_stats
ORDER BY company_type, rank_within_type
LIMIT 20
