SELECT
  t.production_year,
  COUNT(DISTINCT t.id) AS movie_count,
  COUNT(DISTINCT mc.company_id) FILTER (WHERE ct.kind = 'production') AS production_company_count,
  AVG(CAST(mi.info AS double)) FILTER (WHERE it.info = 'rating') AS avg_rating,
  COUNT(ci.id) * 1.0 / NULLIF(COUNT(DISTINCT t.id), 0) AS avg_cast_per_movie
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN movie_companies mc ON mc.movie_id = t.id
LEFT JOIN company_type ct ON mc.company_type_id = ct.id
LEFT JOIN movie_info mi ON mi.movie_id = t.id
LEFT JOIN info_type it ON mi.info_type_id = it.id
LEFT JOIN cast_info ci ON ci.movie_id = t.id
WHERE kt.kind = 'movie'
GROUP BY t.production_year
ORDER BY t.production_year
