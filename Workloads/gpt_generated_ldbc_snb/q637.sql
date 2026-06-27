WITH comment_details AS (
  SELECT
    f.id AS forum_id,
    f.title AS forum_title,
    tc.name AS tag_class_name,
    c.id AS comment_id,
    c.length AS comment_length,
    p.id AS creator_id,
    p.gender AS creator_gender
  FROM comment c
  JOIN post po ON c.parent_post_id = po.id
  JOIN forum f ON po.container_forum_id = f.id
  JOIN comment_has_tag_tag cht ON cht.comment_id = c.id
  JOIN tag t ON cht.tag_id = t.id
  JOIN tag_class tc ON t.type_tag_class_id = tc.id
  JOIN person p ON c.creator_person_id = p.id
)
SELECT
  forum_id,
  forum_title,
  tag_class_name,
  COUNT(DISTINCT comment_id) AS comment_cnt,
  AVG(comment_length) AS avg_comment_len,
  COUNT(DISTINCT creator_id) AS distinct_commenters,
  COUNT(DISTINCT CASE WHEN creator_gender = 'male' THEN creator_id END) AS male_commenters,
  COUNT(DISTINCT CASE WHEN creator_gender = 'female' THEN creator_id END) AS female_commenters
FROM comment_details
GROUP BY forum_id, forum_title, tag_class_name
ORDER BY comment_cnt DESC
LIMIT 20
