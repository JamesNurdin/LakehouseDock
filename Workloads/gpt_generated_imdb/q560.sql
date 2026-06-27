WITH rating_info AS (
    SELECT mi.movie_id, mi.info
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'rating'
)
SELECT
    n.name,
    n.gender,
    COUNT(DISTINCT t.id) AS movie_count,
    COUNT(DISTINCT cn.id) AS distinct_characters,
    MIN(t.production_year) AS first_year,
    MAX(t.production_year) AS last_year,
    AVG(CAST(r.info AS DOUBLE)) AS avg_movie_rating
FROM name n
JOIN cast_info ci ON ci.person_id = n.id
JOIN title t ON ci.movie_id = t.id
LEFT JOIN char_name cn ON ci.person_role_id = cn.id
LEFT JOIN rating_info r ON r.movie_id = t.id
GROUP BY n.id, n.name, n.gender
HAVING COUNT(DISTINCT t.id) >= 5
ORDER BY movie_count DESC
LIMIT 100
