SELECT
  t.id AS tag_id,
  t.name AS tag_name,
  tc.name AS tag_class_name,
  COUNT(DISTINCT c.id) AS comment_count,
  COUNT(plc.person_id) AS total_likes,
  COUNT(DISTINCT plc.person_id) AS distinct_liker_count
FROM tag t
JOIN tag_class tc ON t.type_tag_class_id = tc.id
JOIN comment_has_tag_tag cht ON cht.tag_id = t.id
JOIN comment c ON c.id = cht.comment_id
LEFT JOIN person_likes_comment plc ON plc.comment_id = c.id
GROUP BY t.id, t.name, tc.name
ORDER BY total_likes DESC
LIMIT 10
