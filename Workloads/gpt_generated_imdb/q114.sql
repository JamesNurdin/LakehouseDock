WITH comedy_movies AS (
    SELECT DISTINCT mi.movie_id
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'genre' AND LOWER(mi.info) = 'comedy'
),
actor_comedy_stats AS (
    SELECT
        n.id AS person_id,
        n.name AS person_name,
        n.gender,
        COUNT(DISTINCT ci.movie_id) AS comedy_movie_count,
        AVG(t.production_year) AS avg_production_year
    FROM cast_info ci
    JOIN name n ON ci.person_id = n.id
    JOIN title t ON ci.movie_id = t.id
    JOIN comedy_movies cm ON ci.movie_id = cm.movie_id
    GROUP BY n.id, n.name, n.gender
    HAVING COUNT(DISTINCT ci.movie_id) >= 5
)
SELECT
    person_id,
    person_name,
    gender,
    comedy_movie_count,
    avg_production_year,
    RANK() OVER (ORDER BY comedy_movie_count DESC) AS rank_by_comedy_movies
FROM actor_comedy_stats
ORDER BY comedy_movie_count DESC
LIMIT 10
