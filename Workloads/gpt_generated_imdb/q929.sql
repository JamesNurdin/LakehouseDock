SELECT
    t.title AS movie_title,
    t.production_year,
    kt.kind AS kind,
    COUNT(DISTINCT n.id) AS cast_count,
    COUNT(DISTINCT cn.id) AS character_count,
    COUNT(DISTINCT CASE WHEN ct.kind = 'production' THEN cn_company.id END) AS production_company_count,
    COUNT(DISTINCT k.id) AS keyword_count
FROM title t
LEFT JOIN kind_type kt
  ON t.kind_id = kt.id
LEFT JOIN cast_info ci
  ON ci.movie_id = t.id
LEFT JOIN name n
  ON ci.person_id = n.id
LEFT JOIN char_name cn
  ON ci.person_role_id = cn.id
LEFT JOIN movie_companies mc
  ON mc.movie_id = t.id
LEFT JOIN company_type ct
  ON mc.company_type_id = ct.id
LEFT JOIN company_name cn_company
  ON mc.company_id = cn_company.id
LEFT JOIN movie_keyword mk
  ON mk.movie_id = t.id
LEFT JOIN keyword k
  ON mk.keyword_id = k.id
WHERE t.production_year >= 2000
GROUP BY t.id, t.title, t.production_year, kt.kind
ORDER BY cast_count DESC
LIMIT 10
