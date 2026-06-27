WITH actor_movie_stats AS (
    SELECT
        n.id AS actor_id,
        n.name AS actor_name,
        t.production_year,
        COUNT(DISTINCT t.id) AS movies_count,
        AVG(ci.nr_order) AS avg_nr_order
    FROM cast_info ci
    JOIN name n ON ci.person_id = n.id
    JOIN title t ON ci.movie_id = t.id
    WHERE t.production_year IS NOT NULL
      AND t.kind_id = 1
    GROUP BY n.id, n.name, t.production_year
),
actor_char_counts AS (
    SELECT
        n.id AS actor_id,
        cn.name AS character_name,
        COUNT(*) AS role_count
    FROM cast_info ci
    JOIN name n ON ci.person_id = n.id
    JOIN char_name cn ON ci.person_role_id = cn.id
    GROUP BY n.id, cn.name
),
actor_top_character AS (
    SELECT
        actor_id,
        character_name,
        role_count,
        ROW_NUMBER() OVER (PARTITION BY actor_id ORDER BY role_count DESC, character_name) AS rn
    FROM actor_char_counts
)
SELECT
    a.actor_name,
    a.production_year,
    a.movies_count,
    a.avg_nr_order,
    t.character_name AS most_frequent_character,
    t.role_count AS character_appearances
FROM actor_movie_stats a
LEFT JOIN actor_top_character t
    ON a.actor_id = t.actor_id AND t.rn = 1
ORDER BY a.movies_count DESC, a.actor_name
LIMIT 20
