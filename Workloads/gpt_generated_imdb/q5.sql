WITH movie_info_agg AS (
    SELECT
        mi.info_type_id,
        COUNT(DISTINCT mi.movie_id) AS movie_cnt,
        COUNT(*) AS movie_info_rows
    FROM movie_info mi
    GROUP BY mi.info_type_id
),
movie_info_idx_agg AS (
    SELECT
        mii.info_type_id,
        COUNT(DISTINCT mii.movie_id) AS movie_idx_cnt,
        AVG(mii.note) AS avg_note_idx
    FROM movie_info_idx mii
    GROUP BY mii.info_type_id
),
person_info_agg AS (
    SELECT
        pi.info_type_id,
        COUNT(DISTINCT pi.person_id) AS person_cnt,
        COUNT(*) AS person_info_rows
    FROM person_info pi
    GROUP BY pi.info_type_id
)
SELECT
    it.id AS info_type_id,
    it.info AS info_type_name,
    COALESCE(mi.movie_cnt, 0) AS distinct_movie_count,
    COALESCE(mi.movie_info_rows, 0) AS movie_info_row_count,
    COALESCE(mii.movie_idx_cnt, 0) AS distinct_movie_idx_count,
    COALESCE(mii.avg_note_idx, 0) AS avg_note_idx,
    COALESCE(pi.person_cnt, 0) AS distinct_person_count,
    COALESCE(pi.person_info_rows, 0) AS person_info_row_count
FROM info_type it
LEFT JOIN movie_info_agg mi ON mi.info_type_id = it.id
LEFT JOIN movie_info_idx_agg mii ON mii.info_type_id = it.id
LEFT JOIN person_info_agg pi ON pi.info_type_id = it.id
ORDER BY it.id
