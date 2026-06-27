SELECT
  n.id AS person_id,
  n.name AS primary_name,
  n.gender,
  COUNT(DISTINCT cn.id) AS distinct_characters,
  COUNT(DISTINCT an.id) AS distinct_aka_names,
  COUNT(DISTINCT it.id) AS distinct_info_types
FROM name n
LEFT JOIN cast_info ci ON ci.person_id = n.id
LEFT JOIN char_name cn ON ci.person_role_id = cn.id
LEFT JOIN aka_name an ON an.person_id = n.id
LEFT JOIN person_info pi ON pi.person_id = n.id
LEFT JOIN info_type it ON pi.info_type_id = it.id
WHERE n.gender IS NOT NULL
GROUP BY n.id, n.name, n.gender
ORDER BY distinct_characters DESC
LIMIT 10
