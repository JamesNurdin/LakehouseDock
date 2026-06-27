WITH
    cast_counts AS (
        SELECT
            title.id,
            COUNT(DISTINCT cast_info.person_id) AS cast_count
        FROM cast_info
        JOIN title
            ON cast_info.movie_id = title.id
        GROUP BY title.id
    ),
    tagline_movies AS (
        SELECT
            title.id,
            1 AS has_tagline
        FROM movie_info
        JOIN info_type
            ON movie_info.info_type_id = info_type.id
        JOIN title
            ON movie_info.movie_id = title.id
        WHERE info_type.info = 'Tagline'
        GROUP BY title.id
    )
SELECT
    title.production_year,
    COUNT(DISTINCT title.id) AS num_movies,
    AVG(cast_counts.cast_count) AS avg_cast_per_movie,
    COALESCE(SUM(tagline_movies.has_tagline), 0) AS movies_with_tagline
FROM title
LEFT JOIN cast_counts
    ON cast_counts.id = title.id
LEFT JOIN tagline_movies
    ON tagline_movies.id = title.id
GROUP BY title.production_year
ORDER BY title.production_year
