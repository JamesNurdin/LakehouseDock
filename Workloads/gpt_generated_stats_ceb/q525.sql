WITH user_posts AS (
    SELECT u.id,
           COUNT(p.id) AS post_count,
           COALESCE(SUM(p.score), 0) AS total_post_score,
           COALESCE(AVG(p.score), 0) AS avg_post_score,
           COALESCE(SUM(p.viewcount), 0) AS total_views,
           COALESCE(AVG(p.viewcount), 0) AS avg_views
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    GROUP BY u.id
),
user_votes AS (
    SELECT u.id,
           COUNT(v.id) AS vote_cast_count,
           COALESCE(SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END), 0) AS upvote_cast,
           COALESCE(SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END), 0) AS downvote_cast,
           COALESCE(SUM(v.bountyamount), 0) AS total_bounty_given
    FROM users u
    LEFT JOIN votes v ON v.userid = u.id
    GROUP BY u.id
),
user_comments AS (
    SELECT u.id,
           COUNT(c.id) AS comment_count,
           COALESCE(SUM(c.score), 0) AS total_comment_score,
           COALESCE(AVG(c.score), 0) AS avg_comment_score
    FROM users u
    LEFT JOIN comments c ON c.userid = u.id
    GROUP BY u.id
),
user_badges AS (
    SELECT u.id,
           COUNT(b.id) AS badge_count
    FROM users u
    LEFT JOIN badges b ON b.userid = u.id
    GROUP BY u.id
),
user_edits AS (
    SELECT u.id,
           COUNT(ph.id) AS post_history_count
    FROM users u
    LEFT JOIN posthistory ph ON ph.userid = u.id
    GROUP BY u.id
)
SELECT u.id,
       u.reputation,
       up.post_count,
       up.total_post_score,
       up.avg_post_score,
       up.total_views,
       up.avg_views,
       uv.vote_cast_count,
       uv.upvote_cast,
       uv.downvote_cast,
       uv.total_bounty_given,
       uc.comment_count,
       uc.total_comment_score,
       uc.avg_comment_score,
       ub.badge_count,
       ue.post_history_count
FROM users u
LEFT JOIN user_posts up   ON up.id = u.id
LEFT JOIN user_votes uv   ON uv.id = u.id
LEFT JOIN user_comments uc ON uc.id = u.id
LEFT JOIN user_badges ub   ON ub.id = u.id
LEFT JOIN user_edits ue    ON ue.id = u.id
ORDER BY u.reputation DESC
LIMIT 100
