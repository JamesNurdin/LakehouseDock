WITH user_post_stats AS (
  SELECT
    u.id AS user_id,
    u.reputation,
    COUNT(DISTINCT p.id) AS posts_owned,
    COALESCE(SUM(p.score), 0) AS total_post_score,
    COALESCE(SUM(p.viewcount), 0) AS total_views,
    COALESCE(SUM(p.favoritecount), 0) AS total_favorites,
    COALESCE(SUM(p.answercount), 0) AS total_answers,
    COALESCE(SUM(p.commentcount), 0) AS total_comments_on_posts
  FROM users u
  LEFT JOIN posts p ON p.owneruserid = u.id
  GROUP BY u.id, u.reputation
),
user_comment_stats AS (
  SELECT
    u.id AS user_id,
    COUNT(DISTINCT c.id) AS comments_made,
    COALESCE(SUM(c.score), 0) AS total_comment_score
  FROM users u
  LEFT JOIN comments c ON c.userid = u.id
  GROUP BY u.id
),
user_vote_given_stats AS (
  SELECT
    u.id AS user_id,
    COUNT(DISTINCT v.id) AS votes_given,
    SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvotes_given,
    SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvotes_given
  FROM users u
  LEFT JOIN votes v ON v.userid = u.id
  GROUP BY u.id
),
user_vote_received_stats AS (
  SELECT
    u.id AS user_id,
    COUNT(DISTINCT v.id) AS votes_received,
    SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvotes_received,
    SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvotes_received
  FROM users u
  LEFT JOIN posts p ON p.owneruserid = u.id
  LEFT JOIN votes v ON v.postid = p.id
  GROUP BY u.id
),
user_badge_stats AS (
  SELECT
    u.id AS user_id,
    COUNT(DISTINCT b.id) AS badge_count
  FROM users u
  LEFT JOIN badges b ON b.userid = u.id
  GROUP BY u.id
),
user_ph_events AS (
  SELECT
    u.id AS user_id,
    COUNT(DISTINCT ph.id) AS post_history_events
  FROM users u
  LEFT JOIN posthistory ph ON ph.userid = u.id
  GROUP BY u.id
),
user_ph_owned AS (
  SELECT
    u.id AS user_id,
    COUNT(DISTINCT ph.id) AS post_history_on_owned_posts
  FROM users u
  LEFT JOIN posts p ON p.owneruserid = u.id
  LEFT JOIN posthistory ph ON ph.posthistorytypeid = p.id
  GROUP BY u.id
)
SELECT
  u.id AS user_id,
  u.reputation,
  ps.posts_owned,
  ps.total_post_score,
  ps.total_views,
  ps.total_favorites,
  ps.total_answers,
  ps.total_comments_on_posts,
  cs.comments_made,
  cs.total_comment_score,
  vg.votes_given,
  vg.upvotes_given,
  vg.downvotes_given,
  vr.votes_received,
  vr.upvotes_received,
  vr.downvotes_received,
  b.badge_count,
  phe.post_history_events,
  pho.post_history_on_owned_posts,
  (
    ps.posts_owned * 10
    + cs.comments_made * 2
    + vg.upvotes_given * 1
    - vg.downvotes_given * 1
    + b.badge_count * 5
    + vr.upvotes_received * 2
    + phe.post_history_events * 2
    + pho.post_history_on_owned_posts * 3
  ) AS activity_score
FROM users u
LEFT JOIN user_post_stats ps ON ps.user_id = u.id
LEFT JOIN user_comment_stats cs ON cs.user_id = u.id
LEFT JOIN user_vote_given_stats vg ON vg.user_id = u.id
LEFT JOIN user_vote_received_stats vr ON vr.user_id = u.id
LEFT JOIN user_badge_stats b ON b.user_id = u.id
LEFT JOIN user_ph_events phe ON phe.user_id = u.id
LEFT JOIN user_ph_owned pho ON pho.user_id = u.id
ORDER BY activity_score DESC
LIMIT 50
