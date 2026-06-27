WITH info_stats AS (
    SELECT
        mi.movie_id,
        AVG(mi.note) AS avg_note,
        COUNT(*) AS info_cnt
    FROM movie_info_idx mi
    WHERE mi.info_type_id = 1
    GROUP BY mi.movie_id
),
title_info AS (
    SELECT
        t.id,
        t.title,
        t.production_year,
        t.kind_id,
        COALESCE(ist.avg_note, 0) AS avg_note,
        COALESCE(ist.info_cnt, 0) AS info_cnt
    FROM title t
    LEFT JOIN info_stats ist ON ist.movie_id = t.id
    WHERE t.kind_id = 1
)
SELECT
    ti.production_year,
    ti.title,
    ti.avg_note,
    ti.info_cnt,
    ROW_NUMBER() OVER (PARTITION BY ti.production_year ORDER BY ti.avg_note DESC) AS rank_in_year
FROM title_info ti
WHERE ti.avg_note > 0
ORDER BY ti.production_year, rank_in_year
LIMIT 20
