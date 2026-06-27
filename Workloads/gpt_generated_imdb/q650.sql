WITH actor_movies AS (
    SELECT
        n.id AS actor_id,
        n.name AS actor_name,
        t.id AS movie_id,
        t.production_year,
        cn.name AS character_name
    FROM cast_info ci
    JOIN name n ON ci.person_id = n.id
    JOIN title t ON ci.movie_id = t.id
    LEFT JOIN char_name cn ON ci.person_role_id = cn.id
    WHERE t.production_year IS NOT NULL
),
actor_stats AS (
    SELECT
        actor_id,
        actor_name,
        COUNT(DISTINCT movie_id) AS total_movies,
        MIN(production_year) AS first_year,
        MAX(production_year) AS last_year
    FROM actor_movies
    GROUP BY actor_id, actor_name
),
actor_char_counts AS (
    SELECT
        actor_id,
        character_name,
        COUNT(*) AS role_count
    FROM actor_movies
    WHERE character_name IS NOT NULL
    GROUP BY actor_id, character_name
),
actor_top_chars AS (
    SELECT
        actor_id,
        element_at(chars, 1) AS top_char_1,
        element_at(chars, 2) AS top_char_2,
        element_at(chars, 3) AS top_char_3
    FROM (
        SELECT
            actor_id,
            array_agg(character_name ORDER BY role_count DESC) AS chars
        FROM actor_char_counts
        GROUP BY actor_id
    )
)
SELECT
    a.actor_name,
    a.total_movies,
    a.first_year,
    a.last_year,
    COALESCE(t.top_char_1, '') AS top_character_1,
    COALESCE(t.top_char_2, '') AS top_character_2,
    COALESCE(t.top_char_3, '') AS top_character_3
FROM actor_stats a
LEFT JOIN actor_top_chars t ON a.actor_id = t.actor_id
ORDER BY a.total_movies DESC, a.actor_name
LIMIT 100
