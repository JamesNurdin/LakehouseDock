WITH rating_info AS (
    SELECT
        movie_id,
        CAST(info AS DOUBLE) AS rating
    FROM movie_info_idx
    WHERE info_type_id = 5
),
actor_movies AS (
    SELECT
        n.id AS actor_id,
        n.name AS actor_name,
        t.id AS movie_id,
        t.production_year,
        cn.name AS character_name,
        ri.rating
    FROM cast_info ci
    JOIN name n ON ci.person_id = n.id
    JOIN title t ON ci.movie_id = t.id
    LEFT JOIN char_name cn ON ci.person_role_id = cn.id
    LEFT JOIN rating_info ri ON t.id = ri.movie_id
    WHERE t.production_year IS NOT NULL
),
actor_stats AS (
    SELECT
        actor_id,
        actor_name,
        COUNT(DISTINCT movie_id) AS movie_count,
        MIN(production_year) AS first_year,
        MAX(production_year) AS last_year,
        AVG(production_year) AS avg_year,
        AVG(rating) AS avg_rating
    FROM actor_movies
    GROUP BY actor_id, actor_name
),
actor_character_counts AS (
    SELECT
        actor_id,
        actor_name,
        character_name,
        COUNT(*) AS character_count
    FROM actor_movies
    WHERE character_name IS NOT NULL
    GROUP BY actor_id, actor_name, character_name
),
actor_top_character AS (
    SELECT
        actor_id,
        actor_name,
        character_name,
        character_count,
        ROW_NUMBER() OVER (PARTITION BY actor_id ORDER BY character_count DESC) AS rn
    FROM actor_character_counts
)
SELECT
    a.actor_name,
    a.movie_count,
    a.first_year,
    a.last_year,
    a.avg_year,
    a.avg_rating,
    t.character_name,
    t.character_count
FROM actor_stats a
JOIN actor_top_character t
    ON a.actor_id = t.actor_id
WHERE t.rn = 1
ORDER BY a.movie_count DESC
LIMIT 20
