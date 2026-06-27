WITH user_posts AS (
  SELECT u.id AS user_id,
         COUNT(p.id) AS total_posts,
         COALESCE(SUM(p.score), 0) AS total_post_score,
         COALESCE(SUM(p.viewcount), 0) AS total_post_views
  FROM users u
  LEFT JOIN posts p ON p.owneruserid = u.id
  GROUP BY u.id
),
user_comments AS (
  SELECT u.id AS user_id,
         COUNT(c.id) AS total_comments_made,
         COALESCE(SUM(c.score), 0) AS total_comment_score
  FROM users u
  LEFT JOIN comments c ON c.userid = u.id
  GROUP BY u.id
),
user_badges AS (
  SELECT u.id AS user_id,
         COUNT(b.id) AS total_badges
  FROM users u
  LEFT JOIN badges b ON b.userid = u.id
  GROUP BY u.id
),
user_votes_cast AS (
  SELECT u.id AS user_id,
         COUNT(v.id) AS total_votes_cast
  FROM users u
  LEFT JOIN votes v ON v.userid = u.id
  GROUP BY u.id
),
user_votes_received AS (
  SELECT u.id AS user_id,
         COUNT(vr.id) AS total_votes_received
  FROM users u
  LEFT JOIN posts p ON p.owneruserid = u.id
  LEFT JOIN votes vr ON vr.postid = p.id
  GROUP BY u.id
),
user_tag_distinct AS (
  SELECT u.id AS user_id,
         COUNT(DISTINCT t.id) AS distinct_tag_count
  FROM users u
  LEFT JOIN posts p ON p.owneruserid = u.id
  LEFT JOIN tags t ON t.excerptpostid = p.id
  GROUP BY u.id
),
user_edits AS (
  SELECT u.id AS user_id,
         COUNT(ph.id) AS total_edits
  FROM users u
  LEFT JOIN posthistory ph ON ph.userid = u.id
  GROUP BY u.id
),
user_postlinks AS (
  SELECT u.id AS user_id,
         COUNT(pl.id) AS total_postlinks
  FROM users u
  LEFT JOIN posts p ON p.owneruserid = u.id
  LEFT JOIN postlinks pl ON pl.postid = p.id
  GROUP BY u.id
),
user_posthistory_on_posts AS (
  SELECT u.id AS user_id,
         COUNT(ph2.id) AS posthistory_on_owned_posts
  FROM users u
  LEFT JOIN posts p ON p.owneruserid = u.id
  LEFT JOIN posthistory ph2 ON ph2.posthistorytypeid = p.id
  GROUP BY u.id
)
SELECT u.id AS user_id,
       u.reputation,
       COALESCE(up.total_posts, 0) AS total_posts,
       COALESCE(up.total_post_score, 0) AS total_post_score,
       COALESCE(up.total_post_views, 0) AS total_post_views,
       COALESCE(uc.total_comments_made, 0) AS total_comments_made,
       COALESCE(uc.total_comment_score, 0) AS total_comment_score,
       COALESCE(ub.total_badges, 0) AS total_badges,
       COALESCE(uvc.total_votes_cast, 0) AS total_votes_cast,
       COALESCE(uvr.total_votes_received, 0) AS total_votes_received,
       COALESCE(utd.distinct_tag_count, 0) AS distinct_tag_count,
       COALESCE(ue.total_edits, 0) AS total_edits,
       COALESCE(upk.total_postlinks, 0) AS total_postlinks,
       COALESCE(uphp.posthistory_on_owned_posts, 0) AS posthistory_on_owned_posts,
       ROW_NUMBER() OVER (ORDER BY COALESCE(up.total_posts, 0) DESC) AS user_rank
FROM users u
LEFT JOIN user_posts up ON up.user_id = u.id
LEFT JOIN user_comments uc ON uc.user_id = u.id
LEFT JOIN user_badges ub ON ub.user_id = u.id
LEFT JOIN user_votes_cast uvc ON uvc.user_id = u.id
LEFT JOIN user_votes_received uvr ON uvr.user_id = u.id
LEFT JOIN user_tag_distinct utd ON utd.user_id = u.id
LEFT JOIN user_edits ue ON ue.user_id = u.id
LEFT JOIN user_postlinks upk ON upk.user_id = u.id
LEFT JOIN user_posthistory_on_posts uphp ON uphp.user_id = u.id
ORDER BY total_posts DESC, user_id
LIMIT 100
