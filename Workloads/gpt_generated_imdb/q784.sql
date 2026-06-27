SELECT
    n.name,
    n.id AS person_id,
    COUNT(DISTINCT ci.movie_id) AS movie_count,
    MIN(t.production_year) AS first_year,
    MAX(t.production_year) AS last_year,
    AVG(CAST(mi.info AS double)) FILTER (WHERE it.info = 'rating') AS avg_rating
FROM name n
JOIN cast_info ci ON ci.person_id = n.id
JOIN title t ON ci.movie_id = t.id
LEFT JOIN movie_info mi ON mi.movie_id = t.id
LEFT JOIN info_type it ON mi.info_type_id = it.id
GROUP BY n.name, n.id
ORDER BY movie_count DESC, avg_rating DESC
LIMIT 10
