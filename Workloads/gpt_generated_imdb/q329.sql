WITH movie_ratings AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        CAST(mi.info AS double) AS rating
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    JOIN movie_info mi ON mi.movie_id = t.id
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE kt.kind = 'movie'
      AND it.info = 'rating'
      AND CAST(mi.info AS double) IS NOT NULL
      AND t.production_year >= 2000
)
SELECT
    n.id AS actor_id,
    n.name AS actor_name,
    COUNT(DISTINCT mr.movie_id) AS movie_count,
    AVG(mr.rating) AS avg_rating,
    MIN(mr.production_year) AS first_year,
    MAX(mr.production_year) AS last_year
FROM cast_info ci
JOIN name n ON ci.person_id = n.id
JOIN movie_ratings mr ON ci.movie_id = mr.movie_id
GROUP BY n.id, n.name
HAVING COUNT(DISTINCT mr.movie_id) >= 5
ORDER BY AVG(mr.rating) DESC
LIMIT 10
