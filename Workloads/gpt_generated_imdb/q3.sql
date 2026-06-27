WITH actor_year_counts AS (
    SELECT
        t.production_year,
        n.id AS actor_id,
        n.name AS actor_name,
        COUNT(*) AS appearances
    FROM cast_info ci
    JOIN title t
        ON ci.movie_id = t.id
    JOIN name n
        ON ci.person_id = n.id
    WHERE t.production_year IS NOT NULL
    GROUP BY t.production_year, n.id, n.name
),
ranked_actors AS (
    SELECT
        production_year,
        actor_id,
        actor_name,
        appearances,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY appearances DESC) AS rn
    FROM actor_year_counts
)
SELECT
    production_year,
    actor_name,
    appearances
FROM ranked_actors
WHERE rn <= 5
ORDER BY production_year DESC, appearances DESC
