SELECT
  n.id AS person_id,
  n.name AS person_name,
  n.gender,
  COUNT(DISTINCT ci.movie_id) AS movie_count,
  COUNT(DISTINCT ak.id) AS aka_name_count,
  COUNT(DISTINCT pi.id) AS person_info_entry_count,
  COUNT(DISTINCT it.id) AS distinct_person_info_type_count
FROM name n
JOIN cast_info ci ON ci.person_id = n.id
LEFT JOIN aka_name ak ON ak.person_id = n.id
LEFT JOIN person_info pi ON pi.person_id = n.id
LEFT JOIN info_type it ON pi.info_type_id = it.id
WHERE n.gender = 'M'
GROUP BY n.id, n.name, n.gender
HAVING COUNT(DISTINCT ci.movie_id) >= 5
ORDER BY movie_count DESC, person_id
LIMIT 10
