WITH actor_movies AS (
    SELECT
        name.id AS person_id,
        name.name AS person_name,
        title.id AS movie_id,
        title.production_year,
        CAST(movie_info.info AS double) AS rating
    FROM cast_info
    JOIN name ON cast_info.person_id = name.id
    JOIN title ON cast_info.movie_id = title.id
    JOIN kind_type ON title.kind_id = kind_type.id
    JOIN movie_info ON title.id = movie_info.movie_id
    JOIN info_type ON movie_info.info_type_id = info_type.id
    WHERE kind_type.kind = 'movie'
      AND title.production_year >= 2000
      AND info_type.info = 'rating'
)
SELECT
    person_name,
    COUNT(DISTINCT movie_id) AS movie_count,
    AVG(rating) AS avg_rating
FROM actor_movies
GROUP BY person_name
ORDER BY movie_count DESC, avg_rating DESC
LIMIT 10
