WITH movie_cast_counts AS (
    SELECT
        title.id AS movie_id,
        title.kind_id,
        title.production_year,
        COUNT(cast_info.person_id) AS cast_count
    FROM title
    JOIN cast_info ON cast_info.movie_id = title.id
    WHERE title.production_year >= 2000
    GROUP BY title.id, title.kind_id, title.production_year
)
SELECT
    movie_cast_counts.production_year,
    kind_type.kind,
    COUNT(*) AS movies_count,
    AVG(movie_cast_counts.cast_count) AS avg_cast_per_movie,
    SUM(movie_cast_counts.cast_count) AS total_cast_entries
FROM movie_cast_counts
JOIN kind_type ON movie_cast_counts.kind_id = kind_type.id
GROUP BY movie_cast_counts.production_year, kind_type.kind
ORDER BY movie_cast_counts.production_year DESC, movies_count DESC
