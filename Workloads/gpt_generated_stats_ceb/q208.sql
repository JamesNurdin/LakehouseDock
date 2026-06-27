WITH user_posts AS (
    SELECT u.id AS userid,
           COUNT(p.id) AS post_count,
           SUM(p.score) AS total_post_score,
           SUM(p.viewcount) AS total_views,
           AVG(p.answercount) AS avg_answer_count,
           MAX(p.creationdate) AS latest_post_date
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    GROUP BY u.id
),
user_comments AS (
    SELECT u.id AS userid,
           COUNT(c.id) AS comment_count,
           SUM(c.score) AS total_comment_score,
           AVG(c.score) AS avg_comment_score
    FROM users u
    LEFT JOIN comments c
        ON c.userid = u.id
    GROUP BY u.id
),
user_votes AS (
    SELECT u.id AS userid,
           COUNT(v.id) AS vote_count,
           SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_count,
           SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_count,
           COALESCE(SUM(v.bountyamount), 0) AS total_bounty_given
    FROM users u
    LEFT JOIN votes v
        ON v.userid = u.id
    GROUP BY u.id
),
user_badges AS (
    SELECT u.id AS userid,
           COUNT(b.id) AS badge_count
    FROM users u
    LEFT JOIN badges b
        ON b.userid = u.id
    GROUP BY u.id
)
SELECT up.userid,
       up.post_count,
       up.total_post_score,
       up.total_views,
       up.avg_answer_count,
       uc.comment_count,
       uc.total_comment_score,
       uc.avg_comment_score,
       uv.vote_count,
       uv.upvote_count,
       uv.downvote_count,
       uv.total_bounty_given,
       ub.badge_count
FROM user_posts up
LEFT JOIN user_comments uc ON uc.userid = up.userid
LEFT JOIN user_votes uv ON uv.userid = up.userid
LEFT JOIN user_badges ub ON ub.userid = up.userid
ORDER BY up.total_post_score DESC
LIMIT 100
