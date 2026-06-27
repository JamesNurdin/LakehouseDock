WITH mi_counts AS (
    SELECT
        movie_id,
        info_type_id,
        COUNT(*) AS mi_cnt
    FROM movie_info
    GROUP BY movie_id, info_type_id
),
mi_idx_counts AS (
    SELECT
        movie_id,
        info_type_id,
        COUNT(*) AS mi_idx_cnt
    FROM movie_info_idx
    GROUP BY movie_id, info_type_id
),
combined AS (
    SELECT
        COALESCE(mi.movie_id, mi_idx.movie_id) AS movie_id,
        COALESCE(mi.info_type_id, mi_idx.info_type_id) AS info_type_id,
        COALESCE(mi.mi_cnt, 0) AS mi_cnt,
        COALESCE(mi_idx.mi_idx_cnt, 0) AS mi_idx_cnt
    FROM mi_counts mi
    FULL OUTER JOIN mi_idx_counts mi_idx
        ON mi.movie_id = mi_idx.movie_id
        AND mi.info_type_id = mi_idx.info_type_id
)
SELECT
    t.title,
    t.production_year,
    it.info AS info_type,
    combined.mi_cnt,
    combined.mi_idx_cnt,
    (combined.mi_cnt + combined.mi_idx_cnt) AS total_info_entries,
    ROW_NUMBER() OVER (PARTITION BY it.info ORDER BY (combined.mi_cnt + combined.mi_idx_cnt) DESC) AS rank_in_info_type
FROM combined
JOIN title t
    ON t.id = combined.movie_id
JOIN info_type it
    ON it.id = combined.info_type_id
WHERE (combined.mi_cnt + combined.mi_idx_cnt) > 0
ORDER BY total_info_entries DESC
LIMIT 100
