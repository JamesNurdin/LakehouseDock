WITH actor_movie_counts AS (
    SELECT
        n.id AS actor_id,
        n.name AS actor_name,
        t.production_year,
        kt.kind AS kind,
        COUNT(DISTINCT t.id) AS movie_count
    FROM cast_info ci
    JOIN name n
        ON ci.person_id = n.id
    JOIN title t
        ON ci.movie_id = t.id
    JOIN kind_type kt
        ON t.kind_id = kt.id
    WHERE t.production_year IS NOT NULL
    GROUP BY n.id, n.name, t.production_year, kt.kind
)
SELECT
    actor_name,
    production_year,
    kind,
    movie_count,
    rn AS rank
FROM (
    SELECT
        actor_name,
        production_year,
        kind,
        movie_count,
        ROW_NUMBER() OVER (PARTITION BY production_year, kind ORDER BY movie_count DESC) AS rn
    FROM actor_movie_counts
) ranked
WHERE rn <= 5
ORDER BY production_year, kind, rn
