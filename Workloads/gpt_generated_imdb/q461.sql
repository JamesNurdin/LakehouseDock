WITH actor_movies AS (
    SELECT
        n.id   AS actor_id,
        n.name AS actor_name,
        t.id   AS movie_id
    FROM cast_info ci
    JOIN name n ON ci.person_id = n.id
    JOIN title t ON ci.movie_id = t.id
    JOIN kind_type kt ON t.kind_id = kt.id
    JOIN movie_keyword mk ON t.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    WHERE kt.kind = 'movie'
      AND t.production_year BETWEEN 2000 AND 2020
      AND k.keyword = 'love'
)
SELECT
    actor_id,
    actor_name,
    COUNT(DISTINCT movie_id) AS movie_count
FROM actor_movies
GROUP BY actor_id, actor_name
ORDER BY movie_count DESC
LIMIT 10
