WITH movie_info_stats AS (
    SELECT
        mi.movie_id,
        COUNT(*) AS info_count,
        COUNT(DISTINCT mi.info_type_id) AS distinct_info_types,
        AVG(mi.note) AS avg_note
    FROM movie_info_idx mi
    GROUP BY mi.movie_id
)
SELECT
    t.id,
    t.title,
    t.production_year,
    t.kind_id,
    COALESCE(s.info_count, 0) AS info_count,
    COALESCE(s.distinct_info_types, 0) AS distinct_info_types,
    s.avg_note,
    ROW_NUMBER() OVER (ORDER BY COALESCE(s.info_count, 0) DESC) AS info_rank
FROM title t
LEFT JOIN movie_info_stats s
    ON s.movie_id = t.id
WHERE t.production_year >= 2000
ORDER BY info_rank
LIMIT 50
