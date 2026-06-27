WITH type_stats AS (
    SELECT
        ct.kind,
        COUNT(*) AS total_entries,
        COUNT(DISTINCT mc.movie_id) AS distinct_movies,
        COUNT(DISTINCT mc.company_id) AS distinct_companies,
        AVG(CASE WHEN mc.note IS NOT NULL THEN 1 ELSE 0 END) AS avg_note_present,
        (COUNT(*) * 1.0) / NULLIF(COUNT(DISTINCT mc.movie_id), 0) AS avg_entries_per_movie,
        approx_percentile(length(mc.note), 0.5) AS median_note_length
    FROM movie_companies mc
    JOIN company_type ct
        ON mc.company_type_id = ct.id
    GROUP BY ct.kind
)
SELECT
    kind,
    total_entries,
    distinct_movies,
    distinct_companies,
    (avg_note_present * 100) AS pct_entries_with_note,
    avg_entries_per_movie,
    median_note_length
FROM type_stats
ORDER BY total_entries DESC
LIMIT 10
