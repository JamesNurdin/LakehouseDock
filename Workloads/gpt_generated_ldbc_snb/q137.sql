SELECT
    f.id AS forum_id,
    f.title AS forum_title,
    concat(m.first_name, ' ', m.last_name) AS moderator_name,
    COUNT(DISTINCT p.id) AS num_posts,
    COUNT(DISTINCT pt.tag_id) AS num_distinct_tags,
    COUNT(DISTINCT tc.id) AS num_distinct_tag_classes,
    COUNT(DISTINCT fm.person_id) AS num_members,
    AVG(p.length) AS avg_post_length
FROM forum f
JOIN person m
  ON f.moderator_person_id = m.id
JOIN post p
  ON p.container_forum_id = f.id
JOIN post_has_tag_tag pt
  ON pt.post_id = p.id
JOIN tag t
  ON t.id = pt.tag_id
JOIN tag_class tc
  ON t.type_tag_class_id = tc.id
LEFT JOIN forum_has_member_person fm
  ON fm.forum_id = f.id
GROUP BY f.id, f.title, m.first_name, m.last_name
ORDER BY num_posts DESC
LIMIT 5
