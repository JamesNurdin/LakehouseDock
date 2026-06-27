WITH company_movie_counts AS (
    SELECT
        ct.kind AS company_type,
        mc.company_id,
        COUNT(DISTINCT mc.movie_id) AS movie_count,
        MIN(t.production_year) AS first_year,
        MAX(t.production_year) AS last_year
    FROM movie_companies mc
    JOIN title t
        ON mc.movie_id = t.id
    JOIN company_type ct
        ON mc.company_type_id = ct.id
    GROUP BY ct.kind, mc.company_id
),
ranked_companies AS (
    SELECT
        company_type,
        company_id,
        movie_count,
        first_year,
        last_year,
        RANK() OVER (PARTITION BY company_type ORDER BY movie_count DESC) AS rank_in_type
    FROM company_movie_counts
)
SELECT
    company_type,
    company_id,
    movie_count,
    first_year,
    last_year,
    rank_in_type
FROM ranked_companies
WHERE rank_in_type <= 5
ORDER BY company_type, rank_in_type
