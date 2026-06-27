WITH movie_notes AS (
    SELECT
        mi.movie_id,
        COUNT(*) AS note_count,
        AVG(mi.note) AS avg_note,
        MAX(mi.note) AS max_note,
        MIN(mi.note) AS min_note
    FROM movie_info_idx mi
    GROUP BY mi.movie_id
)
SELECT
    k.kind,
    t.production_year,
    COUNT(DISTINCT t.id) AS movie_count,
    SUM(mn.note_count) AS total_notes,
    AVG(mn.avg_note) AS avg_note_per_movie
FROM title t
JOIN kind_type k ON t.kind_id = k.id
LEFT JOIN movie_notes mn ON mn.movie_id = t.id
WHERE t.production_year >= 2000
GROUP BY k.kind, t.production_year
ORDER BY k.kind, t.production_year DESC
