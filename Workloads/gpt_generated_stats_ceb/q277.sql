-- User activity summary per user
-- Includes posts, comments, votes, badges, and edit history
WITH user_posts AS (
    SELECT
        u.id AS user_id,
        COUNT(p.id) AS post_count,
        COALESCE(SUM(p.score), 0) AS total_post_score,
        COALESCE(SUM(p.viewcount), 0) AS total_post_views,
        COALESCE(SUM(p.favoritecount), 0) AS total_favorite_count,
        COALESCE(SUM(p.answercount), 0) AS total_answer_count,
        COALESCE(SUM(p.commentcount), 0) AS total_comment_on_posts
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    GROUP BY u.id
),
user_comments_made AS (
    SELECT
        u.id AS user_id,
        COUNT(c.id) AS comment_made_count,
        COALESCE(SUM(c.score), 0) AS total_comment_score
    FROM users u
    LEFT JOIN comments c
        ON c.userid = u.id
    GROUP BY u.id
),
user_votes_cast AS (
    SELECT
        u.id AS user_id,
        COUNT(v.id) AS votes_cast_count,
        COALESCE(SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END), 0) AS upvotes_cast,
        COALESCE(SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END), 0) AS downvotes_cast
    FROM users u
    LEFT JOIN votes v
        ON v.userid = u.id
    GROUP BY u.id
),
user_votes_received AS (
    SELECT
        u.id AS user_id,
        COUNT(v.id) AS votes_received_count,
        COALESCE(SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END), 0) AS upvotes_received,
        COALESCE(SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END), 0) AS downvotes_received
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    LEFT JOIN votes v
        ON v.postid = p.id
    GROUP BY u.id
),
user_badges AS (
    SELECT
        u.id AS user_id,
        COUNT(b.id) AS badge_count
    FROM users u
    LEFT JOIN badges b
        ON b.userid = u.id
    GROUP BY u.id
),
user_edits AS (
    SELECT
        u.id AS user_id,
        COUNT(ph.id) AS edit_count
    FROM users u
    LEFT JOIN posthistory ph
        ON ph.userid = u.id
    LEFT JOIN posts p
        ON ph.posthistorytypeid = p.id
    GROUP BY u.id
)
SELECT
    u.id AS user_id,
    u.reputation,
    up.post_count,
    up.total_post_score,
    up.total_post_views,
    up.total_favorite_count,
    up.total_answer_count,
    up.total_comment_on_posts,
    uc.comment_made_count,
    uc.total_comment_score,
    vc.votes_cast_count,
    vc.upvotes_cast,
    vc.downvotes_cast,
    vr.votes_received_count,
    vr.upvotes_received,
    vr.downvotes_received,
    ub.badge_count,
    ue.edit_count
FROM users u
LEFT JOIN user_posts up
    ON up.user_id = u.id
LEFT JOIN user_comments_made uc
    ON uc.user_id = u.id
LEFT JOIN user_votes_cast vc
    ON vc.user_id = u.id
LEFT JOIN user_votes_received vr
    ON vr.user_id = u.id
LEFT JOIN user_badges ub
    ON ub.user_id = u.id
LEFT JOIN user_edits ue
    ON ue.user_id = u.id
ORDER BY u.reputation DESC
LIMIT 100
