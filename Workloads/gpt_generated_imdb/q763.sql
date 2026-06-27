WITH actor_movies AS (
    SELECT
        t.production_year AS production_year,
        n.name          AS actor_name,
        n.id            AS actor_id,
        COUNT(DISTINCT t.id) AS movie_count
    FROM cast_info ci
    JOIN name n       ON ci.person_id = n.id
    JOIN title t      ON ci.movie_id = t.id
    JOIN kind_type kt ON t.kind_id = kt.id
    WHERE kt.kind = 'movie'
      AND t.production_year IS NOT NULL
    GROUP BY t.production_year, n.name, n.id
)
SELECT
    r.production_year,
    r.actor_name,
    r.movie_count
FROM (
    SELECT
        am.production_year,
        am.actor_name,
        am.movie_count,
        ROW_NUMBER() OVER (PARTITION BY am.production_year ORDER BY am.movie_count DESC) AS rn
    FROM actor_movies am
) r
WHERE r.rn <= 5
ORDER BY r.production_year, r.movie_count DESC
