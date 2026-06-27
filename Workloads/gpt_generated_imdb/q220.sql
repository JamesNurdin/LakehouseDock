-- Top 10 actors by the number of distinct movies they have appeared in,
-- including the count of distinct characters they played and the span of production years.
SELECT
    n.name AS person_name,
    COUNT(DISTINCT ci.movie_id) AS movie_count,
    COUNT(DISTINCT cn.id) AS character_count,
    MIN(t.production_year) AS first_year,
    MAX(t.production_year) AS last_year
FROM cast_info ci
JOIN name n ON ci.person_id = n.id
JOIN title t ON ci.movie_id = t.id
LEFT JOIN char_name cn ON ci.person_role_id = cn.id
WHERE t.production_year IS NOT NULL
GROUP BY n.name
ORDER BY movie_count DESC, character_count DESC
LIMIT 10
