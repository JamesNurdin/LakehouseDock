WITH movie_info_counts AS (
    SELECT
        movie_id,
        COUNT(*) AS info_count,
        COUNT(DISTINCT info_type_id) AS distinct_info_types,
        AVG(note) AS avg_note_per_movie,
        MAX(note) AS max_note_per_movie
    FROM movie_info_idx
    GROUP BY movie_id
),
movie_details AS (
    SELECT
        t.id,
        t.title,
        t.production_year,
        t.kind_id,
        i.info_count,
        i.distinct_info_types,
        i.avg_note_per_movie,
        i.max_note_per_movie
    FROM title t
    JOIN movie_info_counts i
        ON i.movie_id = t.id
    WHERE t.kind_id = 1
        AND t.production_year IS NOT NULL
)
SELECT
    floor(m.production_year / 10) * 10 AS decade_start,
    COUNT(*) AS movie_count,
    AVG(m.avg_note_per_movie) AS avg_note_per_decade,
    SUM(m.info_count) AS total_info_entries,
    AVG(m.distinct_info_types) AS avg_distinct_info_types_per_movie
FROM movie_details m
GROUP BY floor(m.production_year / 10) * 10
ORDER BY avg_note_per_decade DESC
LIMIT 5
