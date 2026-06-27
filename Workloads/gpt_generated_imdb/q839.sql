WITH info_type_stats AS (
    SELECT
        it.id AS info_type_id,
        it.info AS info_type,
        COUNT(DISTINCT mi.movie_id) AS movie_count,
        AVG(t.production_year) AS avg_production_year,
        COUNT(DISTINCT mi.info) AS distinct_info_count
    FROM movie_info mi
    JOIN title t
        ON mi.movie_id = t.id
    JOIN info_type it
        ON mi.info_type_id = it.id
    WHERE t.production_year >= 2000
    GROUP BY it.id, it.info
)
SELECT
    info_type,
    movie_count,
    avg_production_year,
    distinct_info_count
FROM info_type_stats
ORDER BY movie_count DESC
LIMIT 10
