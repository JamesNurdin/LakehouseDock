WITH user_badges AS (
    SELECT u.id AS user_id,
           COUNT(b.id) AS badge_count
    FROM users u
    LEFT JOIN badges b
      ON b.userid = u.id
    GROUP BY u.id
),
user_posts AS (
    SELECT u.id AS user_id,
           COUNT(p.id) AS post_count,
           COALESCE(SUM(p.score), 0) AS total_score,
           CASE WHEN COUNT(p.id) = 0 THEN 0 ELSE CAST(SUM(p.score) AS double) / COUNT(p.id) END AS avg_score,
           COALESCE(SUM(p.answercount), 0) AS total_answers,
           COALESCE(SUM(p.commentcount), 0) AS total_comments,
           COALESCE(SUM(p.favoritecount), 0) AS total_favorites
    FROM users u
    LEFT JOIN posts p
      ON p.owneruserid = u.id
    GROUP BY u.id
),
user_votes_received AS (
    SELECT u.id AS user_id,
           COUNT(v.id) AS votes_received,
           SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS upvotes_received,
           SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS downvotes_received
    FROM users u
    LEFT JOIN posts p
      ON p.owneruserid = u.id
    LEFT JOIN votes v
      ON v.postid = p.id
    GROUP BY u.id
),
user_votes_cast AS (
    SELECT u.id AS user_id,
           COUNT(v.id) AS votes_cast,
           SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS upvotes_cast,
           SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS downvotes_cast
    FROM users u
    LEFT JOIN votes v
      ON v.userid = u.id
    GROUP BY u.id
),
user_comments AS (
    SELECT u.id AS user_id,
           COUNT(c.id) AS comments_made
    FROM users u
    LEFT JOIN comments c
      ON c.userid = u.id
    GROUP BY u.id
),
user_tags AS (
    SELECT u.id AS user_id,
           COALESCE(SUM(t.count), 0) AS total_tag_count
    FROM users u
    LEFT JOIN posts p
      ON p.owneruserid = u.id
    LEFT JOIN tags t
      ON t.excerptpostid = p.id
    GROUP BY u.id
),
user_edits AS (
    SELECT u.id AS user_id,
           COUNT(ph.id) AS edit_count
    FROM users u
    LEFT JOIN posthistory ph
      ON ph.userid = u.id
    GROUP BY u.id
)
SELECT u.id,
       u.reputation,
       ub.badge_count,
       up.post_count,
       up.total_score,
       up.avg_score,
       up.total_answers,
       up.total_comments,
       up.total_favorites,
       uvrc.votes_received,
       uvrc.upvotes_received,
       uvrc.downvotes_received,
       uvc.votes_cast,
       uvc.upvotes_cast,
       uvc.downvotes_cast,
       uc.comments_made,
       ut.total_tag_count,
       ue.edit_count
FROM users u
LEFT JOIN user_badges ub
  ON ub.user_id = u.id
LEFT JOIN user_posts up
  ON up.user_id = u.id
LEFT JOIN user_votes_received uvrc
  ON uvrc.user_id = u.id
LEFT JOIN user_votes_cast uvc
  ON uvc.user_id = u.id
LEFT JOIN user_comments uc
  ON uc.user_id = u.id
LEFT JOIN user_tags ut
  ON ut.user_id = u.id
LEFT JOIN user_edits ue
  ON ue.user_id = u.id
ORDER BY up.total_score DESC
LIMIT 10
