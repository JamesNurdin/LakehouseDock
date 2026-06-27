WITH movie_counts AS (
    SELECT
        info_type.id AS info_type_id,
        info_type.info AS info_type_name,
        COUNT(DISTINCT movie_info.movie_id) AS distinct_movie_cnt,
        COUNT(movie_info.id) AS movie_info_cnt
    FROM movie_info
    JOIN info_type
        ON movie_info.info_type_id = info_type.id
    GROUP BY
        info_type.id,
        info_type.info
),
person_counts AS (
    SELECT
        info_type.id AS info_type_id,
        COUNT(DISTINCT person_info.person_id) AS distinct_person_cnt,
        COUNT(person_info.id) AS person_info_cnt
    FROM person_info
    JOIN info_type
        ON person_info.info_type_id = info_type.id
    GROUP BY
        info_type.id
),
movie_idx_stats AS (
    SELECT
        info_type.id AS info_type_id,
        AVG(movie_info_idx.note) AS avg_idx_note,
        COUNT(movie_info_idx.id) AS idx_cnt
    FROM movie_info_idx
    JOIN info_type
        ON movie_info_idx.info_type_id = info_type.id
    GROUP BY
        info_type.id
)
SELECT
    mc.info_type_name,
    mc.distinct_movie_cnt,
    mc.movie_info_cnt,
    pc.distinct_person_cnt,
    pc.person_info_cnt,
    mis.avg_idx_note,
    mis.idx_cnt
FROM movie_counts mc
LEFT JOIN person_counts pc
    ON mc.info_type_id = pc.info_type_id
LEFT JOIN movie_idx_stats mis
    ON mc.info_type_id = mis.info_type_id
ORDER BY mc.movie_info_cnt DESC
LIMIT 20
