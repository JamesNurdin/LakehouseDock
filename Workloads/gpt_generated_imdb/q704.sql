WITH mi_agg AS (
    SELECT
        mi.movie_id,
        COUNT(*) AS movie_info_rows,
        COUNT(DISTINCT mi.info_type_id) AS distinct_info_type_in_movie_info
    FROM movie_info mi
    GROUP BY mi.movie_id
),
mid_idx_agg AS (
    SELECT
        mi_idx.movie_id,
        COUNT(*) AS movie_info_idx_rows,
        COUNT(DISTINCT mi_idx.info_type_id) AS distinct_info_type_in_movie_info_idx,
        AVG(mi_idx.note) AS avg_note_idx
    FROM movie_info_idx mi_idx
    GROUP BY mi_idx.movie_id
)
SELECT
    t.title,
    t.production_year,
    COALESCE(mi_agg.movie_info_rows, 0) AS movie_info_rows,
    COALESCE(mi_agg.distinct_info_type_in_movie_info, 0) AS distinct_info_type_in_movie_info,
    COALESCE(mid_idx_agg.movie_info_idx_rows, 0) AS movie_info_idx_rows,
    COALESCE(mid_idx_agg.distinct_info_type_in_movie_info_idx, 0) AS distinct_info_type_in_movie_info_idx,
    ROUND(COALESCE(mid_idx_agg.avg_note_idx, 0), 2) AS avg_note_idx,
    RANK() OVER (ORDER BY COALESCE(mid_idx_agg.avg_note_idx, 0) DESC) AS rank_by_avg_note
FROM title t
LEFT JOIN mi_agg ON mi_agg.movie_id = t.id
LEFT JOIN mid_idx_agg ON mid_idx_agg.movie_id = t.id
WHERE t.production_year > 2000
ORDER BY avg_note_idx DESC
LIMIT 20
