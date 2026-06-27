WITH kw_counts AS (
    SELECT mk.movie_id,
           COUNT(DISTINCT mk.keyword_id) AS kw_count
    FROM movie_keyword mk
    GROUP BY mk.movie_id
)
SELECT n.name,
       COUNT(DISTINCT t.id) AS total_movies,
       AVG(COALESCE(kc.kw_count, 0)) AS avg_keywords_per_movie
FROM cast_info ci
JOIN title t ON ci.movie_id = t.id
JOIN kind_type kt ON t.kind_id = kt.id
JOIN name n ON ci.person_id = n.id
LEFT JOIN kw_counts kc ON t.id = kc.movie_id
WHERE kt.kind = 'movie'
  AND t.production_year >= 2000
GROUP BY n.name
ORDER BY total_movies DESC
LIMIT 10
