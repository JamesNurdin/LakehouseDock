WITH user_stats AS (
  SELECT
    u.id AS user_id,
    u.reputation,
    COUNT(DISTINCT p.id) AS total_posts_owned,
    COALESCE(SUM(p.score), 0) AS total_posts_score,
    COALESCE(SUM(p.viewcount), 0) AS total_posts_viewcount,
    COUNT(DISTINCT c.id) AS total_comments_made,
    COALESCE(SUM(c.score), 0) AS total_comments_score,
    COUNT(DISTINCT v.id) AS total_votes_cast,
    SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvotes_cast,
    SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvotes_cast,
    COUNT(DISTINCT b.id) AS total_badges,
    COUNT(DISTINCT ph.id) AS total_posthistory_by_user,
    COUNT(DISTINCT ph2.id) AS total_posthistory_by_owned_posts,
    COUNT(DISTINCT t.id) AS distinct_tags_on_owned_posts
  FROM users u
  LEFT JOIN posts p ON p.owneruserid = u.id
  LEFT JOIN comments c ON c.userid = u.id
  LEFT JOIN votes v ON v.userid = u.id
  LEFT JOIN badges b ON b.userid = u.id
  LEFT JOIN posthistory ph ON ph.userid = u.id
  LEFT JOIN posthistory ph2 ON ph2.posthistorytypeid = p.id
  LEFT JOIN tags t ON t.excerptpostid = p.id
  GROUP BY u.id, u.reputation
)
SELECT
  user_id,
  reputation,
  total_posts_owned,
  total_posts_score,
  total_posts_viewcount,
  total_comments_made,
  total_comments_score,
  total_votes_cast,
  upvotes_cast,
  downvotes_cast,
  total_badges,
  total_posthistory_by_user,
  total_posthistory_by_owned_posts,
  distinct_tags_on_owned_posts
FROM user_stats
ORDER BY total_posts_owned DESC
LIMIT 100
