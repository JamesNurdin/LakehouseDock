SELECT
    f.title AS forum_title,
    tc.name AS tag_class_name,
    COUNT(*) AS total_likes,
    COUNT(DISTINCT pl.person_id) AS unique_likers,
    COUNT(DISTINCT p.id) AS unique_posts,
    SUM(p.length) AS total_post_length
FROM forum AS f
JOIN post AS p
  ON p.container_forum_id = f.id
JOIN person_likes_post AS pl
  ON pl.post_id = p.id
JOIN post_has_tag_tag AS pht
  ON pht.post_id = p.id
JOIN tag AS t
  ON t.id = pht.tag_id
JOIN tag_class AS tc
  ON tc.id = t.type_tag_class_id
GROUP BY f.title, tc.name
ORDER BY total_likes DESC
