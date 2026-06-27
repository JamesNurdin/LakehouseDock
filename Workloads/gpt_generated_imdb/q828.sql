WITH movie_info_agg AS (
    SELECT
        mi.movie_id,
        COUNT(DISTINCT mi.info_type_id) AS distinct_info_type_cnt,
        COUNT(*) AS info_entry_cnt,
        SUM(CASE WHEN mi.note IS NULL THEN 0 ELSE LENGTH(mi.note) END) AS total_note_length
    FROM movie_info mi
    GROUP BY mi.movie_id
),
movie_info_idx_agg AS (
    SELECT
        mi_idx.movie_id,
        COUNT(DISTINCT mi_idx.info_type_id) AS distinct_info_type_idx_cnt,
        COUNT(*) AS info_idx_entry_cnt,
        SUM(COALESCE(mi_idx.note, 0)) AS total_numeric_note_sum
    FROM movie_info_idx mi_idx
    GROUP BY mi_idx.movie_id
)
SELECT
    t.title,
    t.production_year,
    COALESCE(mi_agg.distinct_info_type_cnt, 0) AS distinct_info_type_cnt,
    COALESCE(mi_agg.info_entry_cnt, 0) AS info_entry_cnt,
    COALESCE(mi_idx_agg.distinct_info_type_idx_cnt, 0) AS distinct_info_type_idx_cnt,
    COALESCE(mi_idx_agg.info_idx_entry_cnt, 0) AS info_idx_entry_cnt,
    COALESCE(mi_idx_agg.total_numeric_note_sum, 0) AS total_numeric_note_sum
FROM title t
LEFT JOIN movie_info_agg mi_agg
    ON mi_agg.movie_id = t.id
LEFT JOIN movie_info_idx_agg mi_idx_agg
    ON mi_idx_agg.movie_id = t.id
WHERE t.kind_id = 1
ORDER BY total_numeric_note_sum DESC
LIMIT 10
