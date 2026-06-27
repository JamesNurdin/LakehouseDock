WITH movie_agg AS (
    SELECT
        it.id AS info_type_id,
        it.info AS info_type,
        COUNT(DISTINCT mi.movie_id) AS movie_count,
        AVG(DISTINCT t.production_year) AS avg_production_year
    FROM movie_info mi
    JOIN title t ON mi.movie_id = t.id
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE t.production_year >= 2000
    GROUP BY it.id, it.info
),
person_agg AS (
    SELECT
        it.id AS info_type_id,
        COUNT(DISTINCT pi.person_id) AS person_count
    FROM person_info pi
    JOIN info_type it ON pi.info_type_id = it.id
    GROUP BY it.id
)
SELECT
    ma.info_type,
    ma.movie_count,
    ma.avg_production_year,
    COALESCE(pa.person_count, 0) AS person_count
FROM movie_agg ma
LEFT JOIN person_agg pa ON ma.info_type_id = pa.info_type_id
ORDER BY ma.movie_count DESC
LIMIT 20
