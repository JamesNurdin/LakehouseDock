WITH per_type_stats AS (
    SELECT
        mi.info_type_id,
        COUNT(*) AS total_info_entries,
        COUNT(DISTINCT mi.movie_id) AS distinct_movies,
        AVG(length(mi.info)) AS avg_info_length,
        COUNT(mi.note) AS note_count
    FROM movie_info mi
    WHERE mi.info IS NOT NULL
    GROUP BY mi.info_type_id
)
SELECT
    it.info AS info_type,
    pts.total_info_entries,
    pts.distinct_movies,
    pts.avg_info_length,
    pts.note_count
FROM per_type_stats pts
JOIN info_type it
    ON pts.info_type_id = it.id
ORDER BY pts.distinct_movies DESC, pts.total_info_entries DESC
