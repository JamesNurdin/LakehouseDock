WITH movie_ratings AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        try_cast(mi.info AS double) AS rating
    FROM title t
    JOIN movie_info mi ON mi.movie_id = t.id
    JOIN info_type it ON it.id = mi.info_type_id
    JOIN kind_type kt ON t.kind_id = kt.id
    WHERE it.info = 'rating'
      AND kt.kind = 'movie'
      AND t.production_year IS NOT NULL
)
SELECT
    n.id AS person_id,
    n.name,
    n.gender,
    COUNT(DISTINCT mr.movie_id) AS movie_count,
    AVG(mr.rating) AS avg_rating,
    MIN(mr.production_year) AS first_year,
    MAX(mr.production_year) AS last_year
FROM cast_info ci
JOIN name n ON ci.person_id = n.id
JOIN movie_ratings mr ON ci.movie_id = mr.movie_id
WHERE mr.production_year >= 2000
GROUP BY n.id, n.name, n.gender
HAVING COUNT(DISTINCT mr.movie_id) >= 5
ORDER BY avg_rating DESC, movie_count DESC
LIMIT 10
