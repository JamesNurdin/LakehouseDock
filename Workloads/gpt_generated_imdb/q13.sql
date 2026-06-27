WITH actor_appearances AS (
    SELECT
        ci.person_id,
        n.name,
        t.production_year,
        t.id AS movie_id,
        ci.nr_order,
        ci.role_id
    FROM cast_info ci
    JOIN name n ON ci.person_id = n.id
    JOIN title t ON ci.movie_id = t.id
    WHERE t.kind_id = 1
      AND t.production_year BETWEEN 2000 AND 2020
)
SELECT
    a.name,
    COUNT(DISTINCT a.movie_id) AS movie_count,
    MIN(a.production_year) AS first_year,
    MAX(a.production_year) AS last_year,
    AVG(a.nr_order) AS avg_nr_order,
    COUNT(DISTINCT a.role_id) AS distinct_roles
FROM actor_appearances a
GROUP BY a.name, a.person_id
HAVING COUNT(DISTINCT a.movie_id) >= 5
ORDER BY movie_count DESC
LIMIT 10
