SELECT
    cn.name,
    ct.kind,
    COUNT(DISTINCT t.id) AS movie_count,
    AVG(t.production_year) AS avg_production_year,
    COUNT(DISTINCT mk.keyword_id) AS distinct_keyword_count
FROM movie_companies mc
JOIN title t
  ON mc.movie_id = t.id
JOIN company_name cn
  ON mc.company_id = cn.id
JOIN company_type ct
  ON mc.company_type_id = ct.id
LEFT JOIN movie_keyword mk
  ON mk.movie_id = t.id
WHERE t.production_year >= 2000
GROUP BY cn.name, ct.kind
HAVING COUNT(DISTINCT t.id) >= 5
ORDER BY movie_count DESC
LIMIT 20
