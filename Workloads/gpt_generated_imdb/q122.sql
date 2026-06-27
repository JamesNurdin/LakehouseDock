SELECT
  t.title,
  t.production_year,
  kt.kind,
  COUNT(DISTINCT ci.person_id) AS cast_member_count,
  COUNT(DISTINCT mc.company_id) AS company_count,
  COUNT(DISTINCT mk.keyword_id) AS keyword_count,
  (COUNT(DISTINCT ci.person_id) + COUNT(DISTINCT mc.company_id) + COUNT(DISTINCT mk.keyword_id)) AS total_involvement
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN cast_info ci ON ci.movie_id = t.id
LEFT JOIN movie_companies mc ON mc.movie_id = t.id
LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
WHERE t.production_year >= 2000
GROUP BY t.title, t.production_year, kt.kind
ORDER BY total_involvement DESC
LIMIT 10
