SELECT
  t.id AS tag_id,
  t.name AS tag_name,
  tc.id AS tag_class_id,
  tc.name AS tag_class_name,
  ptc.id AS parent_tag_class_id,
  ptc.name AS parent_tag_class_name,
  COUNT(DISTINCT cht.comment_id) AS comment_cnt,
  COUNT(DISTINCT fht.forum_id)   AS forum_cnt,
  COUNT(DISTINCT pht.person_id)  AS person_cnt,
  COUNT(DISTINCT pht2.post_id)   AS post_cnt,
  (COUNT(DISTINCT cht.comment_id) +
   COUNT(DISTINCT fht.forum_id)   +
   COUNT(DISTINCT pht.person_id)  +
   COUNT(DISTINCT pht2.post_id)) AS total_usage
FROM tag t
LEFT JOIN tag_class tc
  ON t.type_tag_class_id = tc.id
LEFT JOIN tag_class ptc
  ON tc.subclass_of_tag_class_id = ptc.id
LEFT JOIN comment_has_tag_tag cht
  ON cht.tag_id = t.id
LEFT JOIN forum_has_tag_tag fht
  ON fht.tag_id = t.id
LEFT JOIN person_has_interest_tag pht
  ON pht.tag_id = t.id
LEFT JOIN post_has_tag_tag pht2
  ON pht2.tag_id = t.id
GROUP BY
  t.id,
  t.name,
  tc.id,
  tc.name,
  ptc.id,
  ptc.name
ORDER BY total_usage DESC
LIMIT 50
