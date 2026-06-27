WITH company_movie_counts AS (
    SELECT
        cn.id,
        cn.name,
        cn.country_code,
        ct.kind,
        COUNT(mc.movie_id) AS movie_count
    FROM movie_companies mc
    JOIN company_name cn
        ON mc.company_id = cn.id
    JOIN company_type ct
        ON mc.company_type_id = ct.id
    GROUP BY cn.id, cn.name, cn.country_code, ct.kind
),
ranked_companies AS (
    SELECT
        id,
        name,
        country_code,
        kind,
        movie_count,
        ROW_NUMBER() OVER (PARTITION BY kind ORDER BY movie_count DESC) AS rn
    FROM company_movie_counts
)
SELECT
    id,
    name,
    country_code,
    kind,
    movie_count
FROM ranked_companies
WHERE rn <= 5
ORDER BY kind, movie_count DESC
