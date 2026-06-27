WITH user_posts AS (
  SELECT owneruserid AS user_id,
         COUNT(*) AS post_count,
         COALESCE(SUM(score), 0) AS total_post_score
  FROM posts
  GROUP BY owneruserid
),
user_comments AS (
  SELECT userid AS user_id,
         COUNT(*) AS comment_count,
         COALESCE(SUM(score), 0) AS total_comment_score
  FROM comments
  GROUP BY userid
),
user_votes AS (
  SELECT userid AS user_id,
         COUNT(*) AS vote_count,
         COALESCE(SUM(COALESCE(bountyamount, 0)), 0) AS total_bounty_amount
  FROM votes
  GROUP BY userid
),
user_badges AS (
  SELECT userid AS user_id,
         COUNT(*) AS badge_count
  FROM badges
  GROUP BY userid
),
user_edits AS (
  SELECT userid AS user_id,
         COUNT(*) AS edit_count
  FROM posthistory
  GROUP BY userid
)
SELECT u.id AS user_id,
       u.reputation,
       COALESCE(up.post_count, 0) AS post_count,
       COALESCE(up.total_post_score, 0) AS total_post_score,
       COALESCE(uc.comment_count, 0) AS comment_count,
       COALESCE(uc.total_comment_score, 0) AS total_comment_score,
       COALESCE(uv.vote_count, 0) AS vote_count,
       COALESCE(uv.total_bounty_amount, 0) AS total_bounty_amount,
       COALESCE(ub.badge_count, 0) AS badge_count,
       COALESCE(ue.edit_count, 0) AS edit_count,
       (COALESCE(up.total_post_score, 0) +
        COALESCE(uc.total_comment_score, 0) +
        COALESCE(uv.vote_count, 0) * 2 +
        COALESCE(ub.badge_count, 0) * 5) AS activity_score
FROM users u
LEFT JOIN user_posts up   ON up.user_id = u.id
LEFT JOIN user_comments uc ON uc.user_id = u.id
LEFT JOIN user_votes uv   ON uv.user_id = u.id
LEFT JOIN user_badges ub  ON ub.user_id = u.id
LEFT JOIN user_edits ue   ON ue.user_id = u.id
ORDER BY activity_score DESC
LIMIT 10
