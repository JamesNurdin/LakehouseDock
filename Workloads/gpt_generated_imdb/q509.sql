WITH actor_movies AS (
    SELECT
        n.id AS actor_id,
        n.name AS actor_name,
        n.gender,
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        c.name AS character_name
    FROM cast_info ci
    JOIN name n
        ON ci.person_id = n.id
    JOIN title t
        ON ci.movie_id = t.id
    LEFT JOIN char_name c
        ON ci.person_role_id = c.id
    WHERE t.production_year >= 2000
)
SELECT
    actor_name,
    gender,
    COUNT(DISTINCT movie_id) AS num_movies,
    COUNT(DISTINCT character_name) AS num_characters,
    MAX(character_name) AS example_character
FROM actor_movies
GROUP BY actor_name, gender
ORDER BY num_movies DESC
LIMIT 20
