WITH actor_birth_movies AS (
    SELECT
        n.id AS actor_id,
        n.name AS actor_name,
        pi.info AS birth_date,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        MIN(t.production_year) AS earliest_year,
        MAX(t.production_year) AS latest_year,
        AVG(t.production_year) AS avg_year
    FROM name n
    JOIN person_info pi ON pi.person_id = n.id
    JOIN info_type it ON pi.info_type_id = it.id
    JOIN cast_info ci ON ci.person_id = n.id
    JOIN title t ON ci.movie_id = t.id
    WHERE it.info = 'birth date'
    GROUP BY n.id, n.name, pi.info
)
SELECT
    actor_id,
    actor_name,
    birth_date,
    movie_count,
    earliest_year,
    latest_year,
    avg_year
FROM actor_birth_movies
WHERE movie_count >= 10
ORDER BY movie_count DESC
LIMIT 20
