WITH person_info_gender_counts AS (
    SELECT
        pi.info_type_id,
        n.gender,
        COUNT(*) AS person_info_cnt
    FROM person_info pi
    JOIN name n ON pi.person_id = n.id
    GROUP BY pi.info_type_id, n.gender
),
movie_info_counts AS (
    SELECT
        mi.info_type_id,
        COUNT(*) AS movie_info_cnt
    FROM movie_info mi
    GROUP BY mi.info_type_id
),
movie_info_idx_counts AS (
    SELECT
        mi_idx.info_type_id,
        COUNT(*) AS movie_info_idx_cnt
    FROM movie_info_idx mi_idx
    GROUP BY mi_idx.info_type_id
)
SELECT
    it.id,
    it.info,
    COALESCE(mi_cnt.movie_info_cnt, 0) AS movie_info_cnt,
    COALESCE(mi_idx_cnt.movie_info_idx_cnt, 0) AS movie_info_idx_cnt,
    pgc.gender,
    COALESCE(pgc.person_info_cnt, 0) AS person_info_cnt,
    (COALESCE(mi_cnt.movie_info_cnt, 0) + COALESCE(mi_idx_cnt.movie_info_idx_cnt, 0) + COALESCE(pgc.person_info_cnt, 0)) AS total_cnt
FROM info_type it
LEFT JOIN movie_info_counts mi_cnt ON mi_cnt.info_type_id = it.id
LEFT JOIN movie_info_idx_counts mi_idx_cnt ON mi_idx_cnt.info_type_id = it.id
LEFT JOIN person_info_gender_counts pgc ON pgc.info_type_id = it.id
ORDER BY total_cnt DESC
LIMIT 50
