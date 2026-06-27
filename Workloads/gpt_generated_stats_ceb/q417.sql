WITH user_posts AS (
    SELECT
        owneruserid AS user_id,
        COUNT(*) AS post_count,
        SUM(score) AS post_score_sum,
        AVG(score) AS post_score_avg
    FROM posts
    GROUP BY owneruserid
),
user_edits AS (
    SELECT
        lasteditoruserid AS user_id,
        COUNT(*) AS edit_count
    FROM posts
    WHERE lasteditoruserid IS NOT NULL
    GROUP BY lasteditoruserid
),
user_comments AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS comment_count,
        SUM(score) AS comment_score_sum,
        AVG(score) AS comment_score_avg
    FROM comments
    GROUP BY userid
),
user_votes_cast AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS votes_cast_count
    FROM votes
    GROUP BY userid
),
user_votes_received AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS votes_received_count
    FROM votes v
    JOIN posts p ON v.postid = p.id
    GROUP BY p.owneruserid
),
user_badges AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
),
user_posthistory AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS posthistory_count
    FROM posthistory
    GROUP BY userid
)
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(up.post_count, 0)               AS total_posts_owned,
    COALESCE(up.post_score_sum, 0)           AS total_post_score,
    COALESCE(up.post_score_avg, 0)           AS avg_post_score,
    COALESCE(ue.edit_count, 0)               AS total_posts_edited,
    COALESCE(uc.comment_count, 0)            AS total_comments_made,
    COALESCE(uc.comment_score_sum, 0)        AS total_comment_score,
    COALESCE(uc.comment_score_avg, 0)        AS avg_comment_score,
    COALESCE(uvc.votes_cast_count, 0)        AS total_votes_cast,
    COALESCE(uvr.votes_received_count, 0)    AS total_votes_received,
    COALESCE(ub.badge_count, 0)              AS total_badges,
    COALESCE(uph.posthistory_count, 0)       AS total_posthistory_entries
FROM users u
LEFT JOIN user_posts        up  ON up.user_id = u.id
LEFT JOIN user_edits        ue  ON ue.user_id = u.id
LEFT JOIN user_comments     uc  ON uc.user_id = u.id
LEFT JOIN user_votes_cast   uvc ON uvc.user_id = u.id
LEFT JOIN user_votes_received uvr ON uvr.user_id = u.id
LEFT JOIN user_badges       ub  ON ub.user_id = u.id
LEFT JOIN user_posthistory  uph ON uph.user_id = u.id
ORDER BY total_posts_owned DESC, u.reputation DESC
LIMIT 20
