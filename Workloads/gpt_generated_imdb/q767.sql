WITH actor_movies AS (
    SELECT
        n.id AS actor_id,
        n.name AS actor_name,
        t.id AS movie_id,
        t.production_year,
        mi.info AS rating,
        cn.name AS character_name
    FROM cast_info ci
    JOIN name n
        ON ci.person_id = n.id
    JOIN title t
        ON ci.movie_id = t.id
    LEFT JOIN movie_info mi
        ON mi.movie_id = t.id
    LEFT JOIN info_type it
        ON mi.info_type_id = it.id
        AND it.info = 'rating'
    LEFT JOIN char_name cn
        ON ci.person_role_id = cn.id
),
actor_agg AS (
    SELECT
        actor_id,
        actor_name,
        COUNT(DISTINCT movie_id) AS total_movies,
        MIN(production_year) AS first_year,
        MAX(production_year) AS last_year,
        AVG(TRY_CAST(rating AS double)) AS avg_rating
    FROM actor_movies
    WHERE production_year IS NOT NULL
    GROUP BY actor_id, actor_name
),
actor_top_char AS (
    SELECT
        actor_id,
        character_name AS most_common_character,
        ROW_NUMBER() OVER (PARTITION BY actor_id ORDER BY char_cnt DESC, character_name) AS rn
    FROM (
        SELECT
            actor_id,
            character_name,
            COUNT(*) AS char_cnt
        FROM actor_movies
        WHERE character_name IS NOT NULL
        GROUP BY actor_id, character_name
    )
)
SELECT
    a.actor_id,
    a.actor_name,
    a.total_movies,
    a.first_year,
    a.last_year,
    a.avg_rating,
    c.most_common_character
FROM actor_agg a
LEFT JOIN actor_top_char c
    ON a.actor_id = c.actor_id
    AND c.rn = 1
ORDER BY a.total_movies DESC
LIMIT 50
