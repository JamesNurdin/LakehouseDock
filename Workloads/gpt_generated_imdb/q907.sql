/*
  Top 10 actors who have appeared in the most "action" movies released from 2010 onward.
  Only movies (not TV episodes, shorts, etc.) are considered.
*/
SELECT
  n.name        AS actor_name,
  n.gender,
  COUNT(DISTINCT t.id) AS movie_count
FROM cast_info ci
JOIN name n          ON ci.person_id = n.id
JOIN title t         ON ci.movie_id = t.id
JOIN kind_type kt    ON t.kind_id = kt.id
JOIN movie_keyword mk ON t.id = mk.movie_id
JOIN keyword k       ON mk.keyword_id = k.id
WHERE kt.kind = 'movie'
  AND k.keyword = 'action'
  AND t.production_year >= 2010
GROUP BY n.name, n.gender
ORDER BY movie_count DESC
LIMIT 10
