WITH combined_counts AS (
    SELECT
        it.id AS info_type_id,
        it.info AS info_type,
        mi.info AS info,
        COUNT(DISTINCT mi.movie_id) AS movie_cnt,
        0 AS person_cnt
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    GROUP BY it.id, it.info, mi.info

    UNION ALL

    SELECT
        it.id AS info_type_id,
        it.info AS info_type,
        pi.info AS info,
        0 AS movie_cnt,
        COUNT(DISTINCT pi.person_id) AS person_cnt
    FROM person_info pi
    JOIN info_type it ON pi.info_type_id = it.id
    GROUP BY it.id, it.info, pi.info
),
aggregated AS (
    SELECT
        info_type_id,
        info_type,
        info,
        SUM(movie_cnt) AS movie_cnt,
        SUM(person_cnt) AS person_cnt,
        SUM(movie_cnt) + SUM(person_cnt) AS total_cnt
    FROM combined_counts
    GROUP BY info_type_id, info_type, info
)
SELECT
    info_type,
    info,
    movie_cnt,
    person_cnt,
    total_cnt
FROM aggregated
ORDER BY total_cnt DESC
LIMIT 100
