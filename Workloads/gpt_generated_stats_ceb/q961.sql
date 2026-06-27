WITH post_info AS (
  SELECT
    p.id AS post_id,
    p.creationdate AS post_creationdate,
    p.score AS post_score,
    p.viewcount AS post_viewcount,
    o.id AS owner_user_id,
    o.reputation AS owner_reputation,
    e.id AS editor_user_id,
    e.reputation AS editor_reputation
  FROM posts p
  LEFT JOIN users o ON p.owneruserid = o.id
  LEFT JOIN users e ON p.lasteditoruserid = e.id
  WHERE p.posttypeid = 1
),
comment_info AS (
  SELECT
    c.postid AS post_id,
    c.id AS comment_id,
    c.score AS comment_score,
    c.userid AS commenter_user_id,
    u.reputation AS commenter_reputation
  FROM comments c
  LEFT JOIN users u ON c.userid = u.id
)
SELECT
  pi.post_id,
  pi.post_creationdate,
  pi.post_score,
  pi.post_viewcount,
  pi.owner_user_id,
  pi.owner_reputation,
  pi.editor_user_id,
  pi.editor_reputation,
  COUNT(ci.comment_id) AS comment_count,
  AVG(ci.comment_score) AS avg_comment_score,
  SUM(ci.comment_score) AS total_comment_score,
  COUNT(DISTINCT ci.commenter_user_id) AS distinct_commenters,
  AVG(ci.commenter_reputation) AS avg_commenter_reputation
FROM post_info pi
LEFT JOIN comment_info ci ON ci.post_id = pi.post_id
GROUP BY
  pi.post_id,
  pi.post_creationdate,
  pi.post_score,
  pi.post_viewcount,
  pi.owner_user_id,
  pi.owner_reputation,
  pi.editor_user_id,
  pi.editor_reputation
ORDER BY comment_count DESC
LIMIT 100
