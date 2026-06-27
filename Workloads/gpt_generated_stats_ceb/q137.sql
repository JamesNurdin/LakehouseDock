SELECT
  u.id AS user_id,
  u.reputation,
  COALESCE(p.total_posts, 0) AS total_posts,
  COALESCE(p.total_answers, 0) AS total_answers,
  COALESCE(v.total_votes_received, 0) AS total_votes_received,
  COALESCE(v.upvotes_received, 0) AS upvotes_received,
  COALESCE(v.downvotes_received, 0) AS downvotes_received,
  COALESCE(b.total_badges, 0) AS total_badges,
  COALESCE(cm.total_comments_made, 0) AS total_comments_made,
  COALESCE(cr.total_comments_received, 0) AS total_comments_received,
  COALESCE(pl_out.total_outgoing_links, 0) AS total_outgoing_links,
  COALESCE(pl_in.total_incoming_links, 0) AS total_incoming_links,
  COALESCE(t.total_tags, 0) AS total_tags,
  COALESCE(ph.total_history_actions, 0) AS total_history_actions,
  COALESCE(ph_on_owned.total_history_on_owned_posts, 0) AS total_history_on_owned_posts,
  (COALESCE(p.total_posts, 0) * 2
   + COALESCE(cm.total_comments_made, 0)
   + COALESCE(cr.total_comments_received, 0)
   + COALESCE(v.total_votes_received, 0)
   + COALESCE(b.total_badges, 0) * 5) AS engagement_score
FROM users u
LEFT JOIN (
  SELECT owneruserid AS userid,
         COUNT(*) AS total_posts,
         SUM(CASE WHEN posttypeid = 2 THEN 1 ELSE 0 END) AS total_answers
  FROM posts
  GROUP BY owneruserid
) p ON p.userid = u.id
LEFT JOIN (
  SELECT p.owneruserid AS userid,
         COUNT(v.id) AS total_votes_received,
         SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS upvotes_received,
         SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS downvotes_received
  FROM posts p
  JOIN votes v ON v.postid = p.id
  GROUP BY p.owneruserid
) v ON v.userid = u.id
LEFT JOIN (
  SELECT userid, COUNT(*) AS total_badges
  FROM badges
  GROUP BY userid
) b ON b.userid = u.id
LEFT JOIN (
  SELECT userid, COUNT(*) AS total_comments_made
  FROM comments
  GROUP BY userid
) cm ON cm.userid = u.id
LEFT JOIN (
  SELECT p.owneruserid AS userid, COUNT(c.id) AS total_comments_received
  FROM posts p
  JOIN comments c ON c.postid = p.id
  GROUP BY p.owneruserid
) cr ON cr.userid = u.id
LEFT JOIN (
  SELECT p.owneruserid AS userid, COUNT(pl.id) AS total_outgoing_links
  FROM posts p
  JOIN postlinks pl ON pl.postid = p.id
  GROUP BY p.owneruserid
) pl_out ON pl_out.userid = u.id
LEFT JOIN (
  SELECT p.owneruserid AS userid, COUNT(pl.id) AS total_incoming_links
  FROM posts p
  JOIN postlinks pl ON pl.relatedpostid = p.id
  GROUP BY p.owneruserid
) pl_in ON pl_in.userid = u.id
LEFT JOIN (
  SELECT p.owneruserid AS userid, COUNT(t.id) AS total_tags
  FROM posts p
  JOIN tags t ON t.excerptpostid = p.id
  GROUP BY p.owneruserid
) t ON t.userid = u.id
LEFT JOIN (
  SELECT userid, COUNT(*) AS total_history_actions
  FROM posthistory
  GROUP BY userid
) ph ON ph.userid = u.id
LEFT JOIN (
  SELECT p.owneruserid AS userid, COUNT(ph.id) AS total_history_on_owned_posts
  FROM posthistory ph
  JOIN posts p ON ph.posthistorytypeid = p.id
  GROUP BY p.owneruserid
) ph_on_owned ON ph_on_owned.userid = u.id
ORDER BY engagement_score DESC
LIMIT 100
