WITH movie_ratings AS (
    SELECT
        t.id AS movie_id,
        CAST(mi.info AS double) AS rating
    FROM title t
    JOIN movie_info mi ON mi.movie_id = t.id
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'rating'
      AND t.production_year >= 2000
),
actor_movies AS (
    SELECT DISTINCT
        ci.person_id AS name_id,
        n.name AS actor_name,
        ci.movie_id,
        mr.rating
    FROM cast_info ci
    JOIN name n ON ci.person_id = n.id
    LEFT JOIN movie_ratings mr ON mr.movie_id = ci.movie_id
)
SELECT
    actor_name,
    COUNT(DISTINCT movie_id) AS movie_count,
    AVG(rating) AS avg_rating
FROM actor_movies
GROUP BY actor_name
ORDER BY movie_count DESC, avg_rating DESC
LIMIT 10
