WITH company_movie_counts AS (
    SELECT
        mc.company_id,
        ct.kind AS company_type,
        cn.name AS company_name,
        cn.country_code,
        COUNT(DISTINCT mc.movie_id) AS movie_count
    FROM movie_companies mc
    JOIN company_name cn
        ON mc.company_id = cn.id
    JOIN company_type ct
        ON mc.company_type_id = ct.id
    GROUP BY mc.company_id, ct.kind, cn.name, cn.country_code
),
type_stats AS (
    SELECT
        company_type,
        AVG(movie_count) AS avg_movie_count,
        STDDEV_POP(movie_count) AS stddev_movie_count
    FROM company_movie_counts
    GROUP BY company_type
)
SELECT
    cmc.company_name,
    cmc.country_code,
    cmc.company_type,
    cmc.movie_count,
    ts.avg_movie_count,
    ts.stddev_movie_count,
    (cmc.movie_count - ts.avg_movie_count) / NULLIF(ts.stddev_movie_count, 0) AS z_score
FROM company_movie_counts cmc
JOIN type_stats ts
    ON cmc.company_type = ts.company_type
WHERE cmc.movie_count > ts.avg_movie_count
ORDER BY z_score DESC
LIMIT 50
