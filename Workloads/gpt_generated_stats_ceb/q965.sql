/*
  User activity snapshot – combines posts, comments, votes, badges and edit history per user
  and ranks users by a composite activity_score.
*/
WITH user_posts AS (
    SELECT
        u.id AS user_id,
        u.reputation,
        COUNT(p.id) AS post_count,
        SUM(p.score) AS total_post_score,
        AVG(p.score) AS avg_post_score,
        SUM(p.viewcount) AS total_viewcount,
        SUM(p.answercount) AS total_answer_count,
        SUM(p.commentcount) AS total_comment_on_posts
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id  -- allowed join rule
    GROUP BY u.id, u.reputation
),
user_comments AS (
    SELECT
        u.id AS user_id,
        COUNT(c.id) AS comment_count
    FROM users u
    LEFT JOIN comments c
        ON c.userid = u.id  -- allowed join rule
    GROUP BY u.id
),
user_votes_cast AS (
    SELECT
        u.id AS user_id,
        COUNT(v.id) AS votes_cast_count,
        SUM(COALESCE(v.bountyamount, 0)) AS total_bounty_given
    FROM users u
    LEFT JOIN votes v
        ON v.userid = u.id  -- allowed join rule
    GROUP BY u.id
),
user_votes_received AS (
    SELECT
        u.id AS user_id,
        COUNT(v.id) AS votes_received_count
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id  -- allowed join rule
    LEFT JOIN votes v
        ON v.postid = p.id  -- allowed join rule
    GROUP BY u.id
),
user_badges AS (
    SELECT
        u.id AS user_id,
        COUNT(b.id) AS badge_count
    FROM users u
    LEFT JOIN badges b
        ON b.userid = u.id  -- allowed join rule
    GROUP BY u.id
),
user_edits AS (
    SELECT
        u.id AS user_id,
        COUNT(ph.id) AS edit_count
    FROM users u
    LEFT JOIN posthistory ph
        ON ph.userid = u.id  -- allowed join rule
    GROUP BY u.id
)
SELECT
    u.id,
    u.reputation,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.total_post_score, 0) AS total_post_score,
    COALESCE(up.avg_post_score, 0) AS avg_post_score,
    COALESCE(up.total_viewcount, 0) AS total_viewcount,
    COALESCE(up.total_answer_count, 0) AS total_answer_count,
    COALESCE(up.total_comment_on_posts, 0) AS total_comment_on_posts,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uvc.votes_cast_count, 0) AS votes_cast_count,
    COALESCE(uvr.votes_received_count, 0) AS votes_received_count,
    COALESCE(ub.badge_count, 0) AS badge_count,
    COALESCE(ue.edit_count, 0) AS edit_count,
    COALESCE(uvc.total_bounty_given, 0) AS total_bounty_given,
    (
        COALESCE(up.post_count, 0) +
        COALESCE(uc.comment_count, 0) +
        COALESCE(uvc.votes_cast_count, 0) +
        COALESCE(ub.badge_count, 0) +
        COALESCE(ue.edit_count, 0)
    ) AS activity_score
FROM users u
LEFT JOIN user_posts up ON up.user_id = u.id
LEFT JOIN user_comments uc ON uc.user_id = u.id
LEFT JOIN user_votes_cast uvc ON uvc.user_id = u.id
LEFT JOIN user_votes_received uvr ON uvr.user_id = u.id
LEFT JOIN user_badges ub ON ub.user_id = u.id
LEFT JOIN user_edits ue ON ue.user_id = u.id
ORDER BY activity_score DESC
LIMIT 100
