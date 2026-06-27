WITH company_movie_counts AS (
    SELECT
        cn.id AS company_id,
        cn.name AS company_name,
        ct.kind AS company_type,
        COUNT(DISTINCT mc.movie_id) AS movies_count
    FROM movie_companies mc
    JOIN company_name cn
        ON mc.company_id = cn.id
    JOIN company_type ct
        ON mc.company_type_id = ct.id
    JOIN title t
        ON mc.movie_id = t.id
    WHERE t.production_year IS NOT NULL
    GROUP BY cn.id, cn.name, ct.kind
),
ranked_companies AS (
    SELECT
        company_type,
        company_name,
        movies_count,
        ROW_NUMBER() OVER (PARTITION BY company_type ORDER BY movies_count DESC) AS rn
    FROM company_movie_counts
)
SELECT
    company_type,
    company_name,
    movies_count
FROM ranked_companies
WHERE rn <= 10
ORDER BY company_type, movies_count DESC
