SELECT
    n.name AS actor_name,
    COUNT(DISTINCT t.id) AS movie_count,
    COUNT(DISTINCT cn.name) AS distinct_character_count,
    COUNT(DISTINCT co.name) AS distinct_company_count,
    COUNT(DISTINCT k.keyword) AS distinct_keyword_count,
    COUNT(DISTINCT a.name) AS aka_name_count
FROM name n
JOIN cast_info ci ON ci.person_id = n.id
JOIN title t ON ci.movie_id = t.id
JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN char_name cn ON ci.person_role_id = cn.id
LEFT JOIN movie_companies mc ON mc.movie_id = t.id
LEFT JOIN company_name co ON mc.company_id = co.id
LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
LEFT JOIN keyword k ON mk.keyword_id = k.id
LEFT JOIN aka_name a ON a.person_id = n.id
WHERE kt.kind = 'movie'
  AND t.production_year >= 2000
GROUP BY n.name
HAVING COUNT(DISTINCT t.id) >= 5
ORDER BY movie_count DESC
LIMIT 10
