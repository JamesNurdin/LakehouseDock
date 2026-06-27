/*
  Top 10 keywords (genres) by the number of distinct actors who appeared in movies of that keyword
  for feature films released between 2000 and 2020.
*/
SELECT
    k.keyword,
    COUNT(DISTINCT n.id) AS distinct_actor_count,
    COUNT(DISTINCT t.id) AS distinct_movie_count
FROM cast_info ci
JOIN title t               ON ci.movie_id = t.id               -- cast_info → title
JOIN kind_type kt          ON t.kind_id = kt.id               -- title → kind_type
JOIN movie_keyword mk      ON t.id = mk.movie_id               -- title → movie_keyword
JOIN keyword k             ON mk.keyword_id = k.id            -- movie_keyword → keyword
JOIN name n                ON ci.person_id = n.id             -- cast_info → name
WHERE kt.kind = 'movie'                           -- keep only feature films
  AND t.production_year BETWEEN 2000 AND 2020   -- release‑year filter
GROUP BY k.keyword
ORDER BY distinct_actor_count DESC
LIMIT 10
