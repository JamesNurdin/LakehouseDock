WITH actor_genres AS (
    SELECT
        n.id AS name_id,
        n.name,
        it.info AS genre,
        t.id AS movie_id
    FROM cast_info ci
    JOIN name n ON ci.person_id = n.id
    JOIN title t ON ci.movie_id = t.id
    JOIN movie_info mi ON mi.movie_id = t.id
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'genre'
),
actor_stats AS (
    SELECT
        name,
        COUNT(DISTINCT movie_id) AS movie_count,
        COUNT(DISTINCT genre) AS genre_count
    FROM actor_genres
    GROUP BY name
)
SELECT
    name,
    movie_count,
    genre_count
FROM actor_stats
ORDER BY genre_count DESC, movie_count DESC
LIMIT 10
