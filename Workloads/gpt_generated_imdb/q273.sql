WITH mi_counts AS (
    SELECT
        mi.info_type_id,
        COUNT(DISTINCT mi.movie_id) AS movie_info_movie_cnt,
        COUNT(DISTINCT mi.info) AS movie_info_distinct_info_cnt
    FROM movie_info mi
    GROUP BY mi.info_type_id
),

midx_stats AS (
    SELECT
        mi_idx.info_type_id,
        COUNT(DISTINCT mi_idx.movie_id) AS movie_info_idx_movie_cnt,
        AVG(mi_idx.note) AS avg_note,
        COUNT(DISTINCT mi_idx.info) AS movie_info_idx_distinct_info_cnt
    FROM movie_info_idx mi_idx
    GROUP BY mi_idx.info_type_id
),

pi_counts AS (
    SELECT
        pi.info_type_id,
        COUNT(DISTINCT pi.person_id) AS person_cnt,
        COUNT(DISTINCT pi.info) AS person_info_distinct_info_cnt
    FROM person_info pi
    GROUP BY pi.info_type_id
)
SELECT
    it.id AS info_type_id,
    it.info AS info_type,
    COALESCE(mi.movie_info_movie_cnt, 0) AS movie_info_movie_cnt,
    COALESCE(mi.movie_info_distinct_info_cnt, 0) AS movie_info_distinct_info_cnt,
    COALESCE(midx.movie_info_idx_movie_cnt, 0) AS movie_info_idx_movie_cnt,
    COALESCE(midx.avg_note, 0) AS avg_note,
    COALESCE(midx.movie_info_idx_distinct_info_cnt, 0) AS movie_info_idx_distinct_info_cnt,
    COALESCE(pi.person_cnt, 0) AS person_cnt,
    COALESCE(pi.person_info_distinct_info_cnt, 0) AS person_info_distinct_info_cnt
FROM info_type it
LEFT JOIN mi_counts mi ON mi.info_type_id = it.id
LEFT JOIN midx_stats midx ON midx.info_type_id = it.id
LEFT JOIN pi_counts pi ON pi.info_type_id = it.id
ORDER BY (
    COALESCE(mi.movie_info_movie_cnt, 0) +
    COALESCE(midx.movie_info_idx_movie_cnt, 0) +
    COALESCE(pi.person_cnt, 0)
) DESC,
    it.id
