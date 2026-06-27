WITH actor_movie AS (
    SELECT
        n.name AS person_name,
        t.id AS title_id,
        t.title AS movie_title,
        CAST(t.production_year AS integer) AS prod_year,
        cn.name AS character_name,
        mk.keyword_id AS keyword_id
    FROM cast_info ci
    JOIN name n
        ON ci.person_id = n.id
    JOIN title t
        ON ci.movie_id = t.id
    LEFT JOIN char_name cn
        ON ci.person_role_id = cn.id
    LEFT JOIN movie_keyword mk
        ON mk.movie_id = t.id
    WHERE t.production_year >= 2000
)
SELECT
    person_name,
    prod_year,
    COUNT(DISTINCT title_id) AS num_movies,
    COUNT(DISTINCT character_name) AS num_characters,
    COUNT(DISTINCT keyword_id) AS num_keywords
FROM actor_movie
GROUP BY person_name, prod_year
ORDER BY num_movies DESC
LIMIT 20
