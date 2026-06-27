WITH user_posts AS (
   SELECT u.id AS user_id,
          u.reputation,
          p.id AS post_id,
          p.score AS post_score
   FROM users u
   JOIN posts p ON p.owneruserid = u.id
),
user_votes_received AS (
   SELECT up.user_id,
          COUNT(v.id) AS votes_received,
          SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS upvotes_received,
          SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS downvotes_received
   FROM user_posts up
   JOIN votes v ON v.postid = up.post_id
   GROUP BY up.user_id
),
user_comments AS (
   SELECT u.id AS user_id,
          COUNT(c.id) AS comment_count,
          AVG(c.score) AS avg_comment_score
   FROM users u
   JOIN comments c ON c.userid = u.id
   GROUP BY u.id
),
user_badges AS (
   SELECT u.id AS user_id,
          COUNT(b.id) AS badge_count
   FROM users u
   JOIN badges b ON b.userid = u.id
   GROUP BY u.id
),
user_post_links AS (
   SELECT up.user_id,
          COUNT(pl.id) AS post_links_count
   FROM user_posts up
   JOIN postlinks pl ON pl.postid = up.post_id
   GROUP BY up.user_id
),
user_tags AS (
   SELECT up.user_id,
          COUNT(t.id) AS tag_count
   FROM user_posts up
   JOIN tags t ON t.excerptpostid = up.post_id
   GROUP BY up.user_id
),
user_history AS (
   SELECT u.id AS user_id,
          COUNT(ph.id) AS history_events_created
   FROM users u
   JOIN posthistory ph ON ph.userid = u.id
   GROUP BY u.id
),
user_post_history AS (
   SELECT up.user_id,
          COUNT(ph.id) AS post_history_events
   FROM user_posts up
   JOIN posthistory ph ON ph.posthistorytypeid = up.post_id
   GROUP BY up.user_id
),
user_post_agg AS (
   SELECT up.user_id,
          COUNT(up.post_id) AS total_posts,
          AVG(up.post_score) AS avg_post_score
   FROM user_posts up
   GROUP BY up.user_id
)
SELECT u.id,
       u.reputation,
       COALESCE(p.total_posts, 0) AS total_posts,
       COALESCE(p.avg_post_score, 0) AS avg_post_score,
       COALESCE(vv.votes_received, 0) AS votes_received,
       COALESCE(vv.upvotes_received, 0) AS upvotes_received,
       COALESCE(vv.downvotes_received, 0) AS downvotes_received,
       COALESCE(c.comment_count, 0) AS comment_count,
       COALESCE(c.avg_comment_score, 0) AS avg_comment_score,
       COALESCE(b.badge_count, 0) AS badge_count,
       COALESCE(pl.post_links_count, 0) AS post_links_count,
       COALESCE(tg.tag_count, 0) AS tag_count,
       COALESCE(h.history_events_created, 0) AS history_events_created,
       COALESCE(ph.post_history_events, 0) AS post_history_events
FROM users u
LEFT JOIN user_post_agg p ON p.user_id = u.id
LEFT JOIN user_votes_received vv ON vv.user_id = u.id
LEFT JOIN user_comments c ON c.user_id = u.id
LEFT JOIN user_badges b ON b.user_id = u.id
LEFT JOIN user_post_links pl ON pl.user_id = u.id
LEFT JOIN user_tags tg ON tg.user_id = u.id
LEFT JOIN user_history h ON h.user_id = u.id
LEFT JOIN user_post_history ph ON ph.user_id = u.id
ORDER BY votes_received DESC
LIMIT 100
