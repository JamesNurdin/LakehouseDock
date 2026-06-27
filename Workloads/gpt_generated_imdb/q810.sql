WITH actor_movie_roles AS (
    SELECT
        n.id AS name_id,
        n.name AS actor_name,
        n.gender,
        t.id AS title_id,
        t.title AS movie_title,
        t.production_year,
        cn.name AS character_name
    FROM cast_info c
    JOIN name n ON c.person_id = n.id
    JOIN title t ON c.movie_id = t.id
    LEFT JOIN char_name cn ON c.person_role_id = cn.id
    WHERE t.kind_id = 1               -- only feature films
      AND t.production_year IS NOT NULL
)
SELECT
    actor_name,
    gender,
    FLOOR(production_year / 10) * 10 AS decade,
    COUNT(DISTINCT title_id) AS movies_played,
    COUNT(DISTINCT character_name) AS distinct_characters,
    MIN(production_year) AS first_year,
    MAX(production_year) AS last_year
FROM actor_movie_roles
WHERE gender = 'M'
GROUP BY
    actor_name,
    gender,
    FLOOR(production_year / 10) * 10
ORDER BY movies_played DESC
LIMIT 20
