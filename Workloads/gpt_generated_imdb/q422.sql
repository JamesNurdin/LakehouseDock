WITH actor_movies AS (
    SELECT
        n.id AS name_id,
        n.name AS actor_name,
        n.gender,
        t.id AS title_id,
        t.title,
        t.production_year,
        cn.id AS char_id,
        cn.name AS character_name
    FROM cast_info ci
    JOIN name n
        ON ci.person_id = n.id
    JOIN title t
        ON ci.movie_id = t.id
    LEFT JOIN char_name cn
        ON ci.person_role_id = cn.id
    WHERE t.production_year BETWEEN 2000 AND 2020
)
SELECT
    name_id,
    actor_name,
    gender,
    COUNT(DISTINCT title_id) AS movies_2000_2020,
    COUNT(DISTINCT char_id) AS distinct_characters,
    AVG(production_year) AS avg_production_year
FROM actor_movies
GROUP BY
    name_id,
    actor_name,
    gender
HAVING COUNT(DISTINCT title_id) >= 5
ORDER BY movies_2000_2020 DESC
LIMIT 100
