SELECT
    n.id AS person_id,
    n.name AS person_name,
    COUNT(DISTINCT ci.movie_id) AS movie_count,
    COUNT(DISTINCT kw.id) AS distinct_keyword_count,
    CAST(COUNT(DISTINCT kw.id) AS DOUBLE) / COUNT(DISTINCT ci.movie_id) AS avg_keywords_per_movie,
    AVG(t.production_year) AS avg_production_year
FROM cast_info ci
JOIN name n ON ci.person_id = n.id
JOIN title t ON ci.movie_id = t.id
JOIN kind_type kt ON t.kind_id = kt.id
JOIN movie_keyword mk ON mk.movie_id = t.id
JOIN keyword kw ON mk.keyword_id = kw.id
WHERE kt.kind = 'movie'
  AND t.production_year >= 2000
GROUP BY n.id, n.name
HAVING COUNT(DISTINCT ci.movie_id) >= 5
ORDER BY avg_keywords_per_movie DESC
LIMIT 5
