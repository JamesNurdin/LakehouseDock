WITH movie_agg AS (
    SELECT
        it.id AS info_type_id,
        it.info AS info,
        COUNT(DISTINCT mi.movie_id) AS distinct_movie_cnt
    FROM info_type it
    LEFT JOIN movie_info mi
        ON mi.info_type_id = it.id
    GROUP BY it.id, it.info
),
idx_agg AS (
    SELECT
        it.id AS info_type_id,
        AVG(mi_idx.note) AS avg_note_idx
    FROM info_type it
    LEFT JOIN movie_info_idx mi_idx
        ON mi_idx.info_type_id = it.id
    GROUP BY it.id
),
person_agg AS (
    SELECT
        it.id AS info_type_id,
        COUNT(DISTINCT pi.person_id) AS distinct_person_cnt
    FROM info_type it
    LEFT JOIN person_info pi
        ON pi.info_type_id = it.id
    GROUP BY it.id
)
SELECT
    ma.info,
    ma.distinct_movie_cnt,
    ia.avg_note_idx,
    pa.distinct_person_cnt
FROM movie_agg ma
LEFT JOIN idx_agg ia
    ON ia.info_type_id = ma.info_type_id
LEFT JOIN person_agg pa
    ON pa.info_type_id = ma.info_type_id
WHERE ma.info IS NOT NULL
ORDER BY ma.distinct_movie_cnt DESC NULLS LAST
