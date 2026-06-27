WITH title_summary AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.kind_id,
        t.production_year,
        COUNT(DISTINCT it.id) AS distinct_info_type_cnt,
        COUNT(mi.id) AS total_info_entries,
        AVG(mi_idx.note) AS avg_idx_note
    FROM title t
    JOIN movie_info mi
        ON mi.movie_id = t.id
    JOIN info_type it
        ON mi.info_type_id = it.id
    LEFT JOIN movie_info_idx mi_idx
        ON mi_idx.movie_id = t.id
        AND mi_idx.info_type_id = it.id
    WHERE t.production_year IS NOT NULL
    GROUP BY t.id, t.title, t.kind_id, t.production_year
)
SELECT
    kind_id,
    COUNT(DISTINCT title_id) AS num_titles,
    AVG(production_year) AS avg_production_year,
    approx_percentile(production_year, 0.5) AS median_production_year,
    SUM(total_info_entries) AS sum_info_entries,
    AVG(distinct_info_type_cnt) AS avg_distinct_info_types,
    AVG(avg_idx_note) AS avg_idx_note_over_titles
FROM title_summary
WHERE production_year >= 2000
GROUP BY kind_id
ORDER BY num_titles DESC
LIMIT 100
