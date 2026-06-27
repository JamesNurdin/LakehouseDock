WITH company_movie_stats AS (
    SELECT
        cn.id AS company_id,
        cn.name AS company_name,
        cn.country_code,
        ct.kind AS company_type,
        COUNT(DISTINCT mc.movie_id) AS movie_count,
        COUNT(*) AS association_count
    FROM movie_companies mc
    JOIN company_name cn
        ON mc.company_id = cn.id
    JOIN company_type ct
        ON mc.company_type_id = ct.id
    GROUP BY cn.id, cn.name, cn.country_code, ct.kind
    HAVING COUNT(DISTINCT mc.movie_id) > 5
)
SELECT
    company_name,
    country_code,
    company_type,
    movie_count,
    association_count
FROM company_movie_stats
ORDER BY association_count DESC
LIMIT 20
