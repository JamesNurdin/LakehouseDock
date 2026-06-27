WITH actor_movies AS (
    SELECT
        n.id AS person_id,
        n.name AS person_name,
        n.gender,
        t.id AS movie_id,
        t.production_year,
        k.kind
    FROM cast_info ci
    JOIN name n ON ci.person_id = n.id
    JOIN title t ON ci.movie_id = t.id
    JOIN kind_type k ON t.kind_id = k.id
    WHERE t.production_year >= 2000
)
SELECT
    person_id,
    person_name,
    gender,
    COUNT(DISTINCT movie_id) AS movie_count,
    AVG(production_year) AS avg_production_year,
    COUNT(DISTINCT kind) AS distinct_kinds
FROM actor_movies
GROUP BY person_id, person_name, gender
HAVING COUNT(DISTINCT movie_id) >= 5
ORDER BY movie_count DESC
LIMIT 10
