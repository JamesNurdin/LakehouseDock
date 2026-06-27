WITH movie_genre_actors AS (
    SELECT
        t.id AS movie_id,
        t.production_year,
        mi.info AS genre,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        MAX(CASE WHEN n.gender = 'F' THEN 1 ELSE 0 END) AS has_female_actor
    FROM title t
    JOIN movie_info mi
        ON mi.movie_id = t.id
    JOIN info_type it
        ON mi.info_type_id = it.id
    JOIN cast_info ci
        ON ci.movie_id = t.id
    JOIN name n
        ON ci.person_id = n.id
    WHERE it.info = 'genre'
    GROUP BY t.id, t.production_year, mi.info
)
SELECT
    production_year,
    genre,
    COUNT(*) AS movie_count,
    SUM(actor_count) AS total_actors,
    AVG(actor_count) AS avg_actors_per_movie,
    SUM(has_female_actor) AS movies_with_female_actor
FROM movie_genre_actors
GROUP BY production_year, genre
ORDER BY production_year DESC, genre
