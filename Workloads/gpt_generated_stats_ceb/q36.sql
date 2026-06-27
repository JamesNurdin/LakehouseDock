/*
  Analytical query: Top 10 most active Stack Exchange users measured by a composite activity score.
  The score aggregates:
    • post score (owner of posts)
    • comment score (author of comments)
    • votes cast
    • votes received on owned posts
    • badges earned
    • number of tag excerpt posts authored (via tags.excerptpostid)
    • number of post‑link entries created for owned posts
    • number of post‑history edits performed
  All joins follow the allowed join rules.
*/
WITH user_posts AS (
  SELECT p.owneruserid AS userid,
         SUM(p.score) AS total_post_score,
         COUNT(*) AS post_count
  FROM posts p
  GROUP BY p.owneruserid
),
user_comments AS (
  SELECT c.userid AS userid,
         SUM(c.score) AS total_comment_score,
         COUNT(*) AS comment_count
  FROM comments c
  GROUP BY c.userid
),
user_votes_cast AS (
  SELECT v.userid AS userid,
         COUNT(*) AS votes_cast
  FROM votes v
  GROUP BY v.userid
),
user_votes_received AS (
  SELECT p.owneruserid AS userid,
         COUNT(*) AS votes_received,
         SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvotes_received,
         SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvotes_received
  FROM votes v
  JOIN posts p ON v.postid = p.id
  GROUP BY p.owneruserid
),
user_badges AS (
  SELECT b.userid AS userid,
         COUNT(*) AS badge_count
  FROM badges b
  GROUP BY b.userid
),
user_tag_excerpts AS (
  SELECT p.owneruserid AS userid,
         COUNT(DISTINCT t.id) AS tag_excerpt_count
  FROM posts p
  JOIN tags t ON t.excerptpostid = p.id
  GROUP BY p.owneruserid
),
user_post_links AS (
  SELECT p.owneruserid AS userid,
         COUNT(*) AS post_link_count
  FROM postlinks pl
  JOIN posts p ON pl.postid = p.id
  GROUP BY p.owneruserid
),
user_edits AS (
  SELECT ph.userid AS userid,
         COUNT(*) AS edit_count
  FROM posthistory ph
  GROUP BY ph.userid
)
SELECT u.id,
       u.reputation,
       COALESCE(up.total_post_score, 0) AS total_post_score,
       COALESCE(uc.total_comment_score, 0) AS total_comment_score,
       COALESCE(uvc.votes_cast, 0) AS votes_cast,
       COALESCE(uvr.votes_received, 0) AS votes_received,
       COALESCE(ub.badge_count, 0) AS badge_count,
       COALESCE(ute.tag_excerpt_count, 0) AS tag_excerpt_count,
       COALESCE(upl.post_link_count, 0) AS post_link_count,
       COALESCE(ue.edit_count, 0) AS edit_count,
       (COALESCE(up.total_post_score, 0) +
        COALESCE(uc.total_comment_score, 0) +
        COALESCE(uvc.votes_cast, 0) +
        COALESCE(uvr.votes_received, 0) +
        COALESCE(ub.badge_count, 0) +
        COALESCE(ute.tag_excerpt_count, 0) +
        COALESCE(upl.post_link_count, 0) +
        COALESCE(ue.edit_count, 0)) AS activity_score
FROM users u
LEFT JOIN user_posts up ON up.userid = u.id
LEFT JOIN user_comments uc ON uc.userid = u.id
LEFT JOIN user_votes_cast uvc ON uvc.userid = u.id
LEFT JOIN user_votes_received uvr ON uvr.userid = u.id
LEFT JOIN user_badges ub ON ub.userid = u.id
LEFT JOIN user_tag_excerpts ute ON ute.userid = u.id
LEFT JOIN user_post_links upl ON upl.userid = u.id
LEFT JOIN user_edits ue ON ue.userid = u.id
ORDER BY activity_score DESC
LIMIT 10
