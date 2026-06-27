WITH movie_ratings AS (
    SELECT
        mi.movie_id,
        CAST(mi.info AS double) AS rating
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'rating'
)
SELECT
    n.name AS actor_name,
    kt.kind AS kind,
    COUNT(DISTINCT t.id) AS total_movies,
    AVG(mr.rating) AS avg_rating,
    COUNT(DISTINCT mc.company_id) AS distinct_companies
FROM cast_info ci
JOIN name n ON ci.person_id = n.id
JOIN title t ON ci.movie_id = t.id
JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN movie_ratings mr ON mr.movie_id = t.id
LEFT JOIN movie_companies mc ON mc.movie_id = t.id
WHERE t.production_year >= 2000
GROUP BY n.name, kt.kind
ORDER BY total_movies DESC
LIMIT 20
