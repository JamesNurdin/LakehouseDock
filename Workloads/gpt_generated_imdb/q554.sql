WITH rating_info AS (
    SELECT mi.movie_id,
           mi.note AS rating
    FROM movie_info_idx mi
    JOIN info_type it
      ON mi.info_type_id = it.id
    WHERE it.info = 'rating'
)
SELECT n.name AS actor_name,
       COUNT(DISTINCT t.id) AS movie_count,
       AVG(ri.rating) AS avg_rating,
       COUNT(DISTINCT mc.company_id) AS distinct_production_company_count,
       MIN(t.production_year) AS first_year,
       MAX(t.production_year) AS last_year
FROM cast_info ci
JOIN name n
  ON ci.person_id = n.id
JOIN title t
  ON ci.movie_id = t.id
JOIN kind_type kt
  ON t.kind_id = kt.id
LEFT JOIN rating_info ri
  ON t.id = ri.movie_id
LEFT JOIN movie_companies mc
  ON mc.movie_id = t.id
  AND mc.company_type_id = 1
WHERE kt.kind = 'movie'
  AND t.production_year >= 2000
GROUP BY n.name, n.id
ORDER BY movie_count DESC, avg_rating DESC
LIMIT 10
