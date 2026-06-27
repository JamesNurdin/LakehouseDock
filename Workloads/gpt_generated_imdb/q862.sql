WITH company_movie_counts AS (
    SELECT
        mc.company_id,
        mc.company_type_id,
        COUNT(DISTINCT mc.movie_id) AS distinct_movie_count
    FROM movie_companies mc
    GROUP BY mc.company_id, mc.company_type_id
),
ranked_companies AS (
    SELECT
        cn.name,
        cn.country_code,
        ct.kind,
        cmc.distinct_movie_count,
        ROW_NUMBER() OVER (PARTITION BY ct.kind ORDER BY cmc.distinct_movie_count DESC) AS rn
    FROM company_movie_counts cmc
    JOIN company_name cn
        ON cmc.company_id = cn.id
    JOIN company_type ct
        ON cmc.company_type_id = ct.id
)
SELECT
    name,
    country_code,
    kind,
    distinct_movie_count
FROM ranked_companies
WHERE rn <= 5
ORDER BY kind, distinct_movie_count DESC
