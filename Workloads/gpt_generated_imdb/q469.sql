SELECT
    n.name AS actor_name,
    COUNT(DISTINCT cn.name) AS distinct_characters,
    COUNT(DISTINCT ci.id) AS total_appearances
FROM cast_info ci
JOIN name n
    ON ci.person_id = n.id
JOIN char_name cn
    ON ci.person_role_id = cn.id
JOIN title t
    ON ci.movie_id = t.id
JOIN kind_type kt
    ON t.kind_id = kt.id
JOIN movie_keyword mk
    ON mk.movie_id = t.id
JOIN keyword k
    ON mk.keyword_id = k.id
WHERE kt.kind = 'TV Series'
  AND k.keyword = 'drama'
GROUP BY n.name
ORDER BY distinct_characters DESC, total_appearances DESC
LIMIT 5
