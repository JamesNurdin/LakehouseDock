WITH user_posts AS (
    SELECT 
        u.id AS user_id,
        u.reputation,
        COUNT(p.id) AS total_posts,
        COALESCE(SUM(p.score), 0) AS total_post_score,
        COALESCE(SUM(p.viewcount), 0) AS total_views
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    GROUP BY u.id, u.reputation
),
user_votes_received AS (
    SELECT 
        u.id AS user_id,
        COUNT(v.id) AS votes_received
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    LEFT JOIN votes v
        ON v.postid = p.id
    GROUP BY u.id
),
user_votes_cast AS (
    SELECT 
        u.id AS user_id,
        COUNT(v.id) AS votes_cast
    FROM users u
    LEFT JOIN votes v
        ON v.userid = u.id
    GROUP BY u.id
),
user_comments AS (
    SELECT 
        u.id AS user_id,
        COUNT(c.id) AS total_comments_made,
        COALESCE(SUM(c.score), 0) AS total_comment_score
    FROM users u
    LEFT JOIN comments c
        ON c.userid = u.id
    GROUP BY u.id
),
user_badges AS (
    SELECT 
        u.id AS user_id,
        COUNT(b.id) AS total_badges
    FROM users u
    LEFT JOIN badges b
        ON b.userid = u.id
    GROUP BY u.id
),
user_post_edits AS (
    SELECT 
        u.id AS user_id,
        COUNT(ph.id) AS total_edits
    FROM users u
    LEFT JOIN posthistory ph
        ON ph.userid = u.id
    LEFT JOIN posts p
        ON ph.posthistorytypeid = p.id
    GROUP BY u.id
),
user_tag_counts AS (
    SELECT 
        u.id AS user_id,
        COALESCE(SUM(t.count), 0) AS total_tag_count
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    LEFT JOIN tags t
        ON t.excerptpostid = p.id
    GROUP BY u.id
)
SELECT 
    up.user_id,
    up.reputation,
    up.total_posts,
    up.total_post_score,
    CASE WHEN up.total_posts > 0 THEN up.total_post_score / up.total_posts ELSE NULL END AS avg_post_score,
    urv.votes_received,
    CASE WHEN up.total_posts > 0 THEN urv.votes_received / up.total_posts ELSE NULL END AS votes_per_post,
    uvc.votes_cast,
    uc.total_comments_made,
    uc.total_comment_score,
    CASE WHEN uc.total_comments_made > 0 THEN uc.total_comment_score / uc.total_comments_made ELSE NULL END AS avg_comment_score,
    ub.total_badges,
    upe.total_edits,
    ut.total_tag_count
FROM user_posts up
LEFT JOIN user_votes_received urv
    ON urv.user_id = up.user_id
LEFT JOIN user_votes_cast uvc
    ON uvc.user_id = up.user_id
LEFT JOIN user_comments uc
    ON uc.user_id = up.user_id
LEFT JOIN user_badges ub
    ON ub.user_id = up.user_id
LEFT JOIN user_post_edits upe
    ON upe.user_id = up.user_id
LEFT JOIN user_tag_counts ut
    ON ut.user_id = up.user_id
ORDER BY up.total_posts DESC
LIMIT 10
