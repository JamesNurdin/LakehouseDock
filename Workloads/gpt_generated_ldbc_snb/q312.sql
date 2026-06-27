WITH
  post_likes AS (
    SELECT
      p.id AS post_id,
      COUNT(DISTINCT pl.person_id) AS like_count
    FROM
      post p
      LEFT JOIN person_likes_post pl ON pl.post_id = p.id
    GROUP BY
      p.id
  ),
  post_tag_class AS (
    SELECT DISTINCT
      pt.post_id,
      t.type_tag_class_id AS tag_class_id
    FROM
      post_has_tag_tag pt
      JOIN tag t ON pt.tag_id = t.id
  ),
  comment_tag_class AS (
    SELECT DISTINCT
      ct.comment_id,
      t.type_tag_class_id AS tag_class_id
    FROM
      comment_has_tag_tag ct
      JOIN tag t ON ct.tag_id = t.id
  )
SELECT
  tc.name AS tag_class_name,
  COUNT(DISTINCT ptc.post_id) AS post_count,
  COALESCE(SUM(pl.like_count), 0) AS total_post_likes,
  CASE WHEN COUNT(DISTINCT ptc.post_id) > 0 THEN
    SUM(pl.like_count) / COUNT(DISTINCT ptc.post_id)
  END AS avg_likes_per_post,
  COUNT(DISTINCT ctc.comment_id) AS comment_count
FROM
  tag_class tc
  LEFT JOIN post_tag_class ptc ON ptc.tag_class_id = tc.id
  LEFT JOIN post_likes pl ON pl.post_id = ptc.post_id
  LEFT JOIN comment_tag_class ctc ON ctc.tag_class_id = tc.id
GROUP BY
  tc.name
ORDER BY
  total_post_likes DESC
LIMIT 10
