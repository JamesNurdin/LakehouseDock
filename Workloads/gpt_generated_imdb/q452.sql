SELECT
  n.id AS person_id,
  n.name,
  COUNT(DISTINCT ci.movie_id) AS total_movies,
  COUNT(DISTINCT cn.id) AS distinct_characters,
  MIN(t.production_year) AS earliest_year,
  MAX(t.production_year) AS latest_year,
  COUNT(DISTINCT mk.keyword_id) AS total_keywords,
  COUNT(DISTINCT mc.company_id) AS distinct_companies
FROM cast_info ci
JOIN name n ON ci.person_id = n.id
JOIN title t ON ci.movie_id = t.id
LEFT JOIN char_name cn ON ci.person_role_id = cn.id
LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
LEFT JOIN movie_companies mc ON mc.movie_id = t.id
GROUP BY n.id, n.name
HAVING COUNT(DISTINCT ci.movie_id) >= 5
ORDER BY total_movies DESC
LIMIT 100
