WITH user_badges AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
),
user_posts AS (
    SELECT
        u.id AS user_id,
        u.reputation,
        COUNT(p.id) AS post_count,
        COALESCE(SUM(p.score), 0) AS total_post_score,
        COALESCE(AVG(p.viewcount), 0.0) AS avg_post_viewcount
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    GROUP BY u.id, u.reputation
),
user_comments AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS comment_count,
        COALESCE(SUM(score), 0) AS total_comment_score
    FROM comments
    GROUP BY userid
),
user_votes_received AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(v.id) AS votes_received,
        COALESCE(SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END), 0) AS upvotes_received,
        COALESCE(SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END), 0) AS downvotes_received
    FROM posts p
    LEFT JOIN votes v ON v.postid = p.id
    GROUP BY p.owneruserid
),
user_votes_cast AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS votes_cast,
        COALESCE(SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END), 0) AS upvotes_cast,
        COALESCE(SUM(CASE WHEN votetypeid = 3 THEN 1 ELSE 0 END), 0) AS downvotes_cast
    FROM votes
    GROUP BY userid
),
user_tags AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(DISTINCT t.id) AS tag_count
    FROM posts p
    LEFT JOIN tags t ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
),
user_postlinks AS (
    SELECT
        user_id,
        COUNT(DISTINCT link_id) AS postlink_count
    FROM (
        SELECT p.owneruserid AS user_id, pl.id AS link_id
        FROM posts p
        JOIN postlinks pl ON pl.postid = p.id
        UNION ALL
        SELECT p.owneruserid AS user_id, pl.id AS link_id
        FROM posts p
        JOIN postlinks pl ON pl.relatedpostid = p.id
    ) sub
    GROUP BY user_id
)
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(ub.badge_count, 0) AS badge_count,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.total_post_score, 0) AS total_post_score,
    COALESCE(up.avg_post_viewcount, 0.0) AS avg_post_viewcount,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uc.total_comment_score, 0) AS total_comment_score,
    COALESCE(uvr.votes_received, 0) AS votes_received,
    COALESCE(uvr.upvotes_received, 0) AS upvotes_received,
    COALESCE(uvr.downvotes_received, 0) AS downvotes_received,
    COALESCE(uvc.votes_cast, 0) AS votes_cast,
    COALESCE(uvc.upvotes_cast, 0) AS upvotes_cast,
    COALESCE(uvc.downvotes_cast, 0) AS downvotes_cast,
    COALESCE(ut.tag_count, 0) AS tag_count,
    COALESCE(upk.postlink_count, 0) AS postlink_count
FROM users u
LEFT JOIN user_badges ub ON ub.user_id = u.id
LEFT JOIN user_posts up ON up.user_id = u.id
LEFT JOIN user_comments uc ON uc.user_id = u.id
LEFT JOIN user_votes_received uvr ON uvr.user_id = u.id
LEFT JOIN user_votes_cast uvc ON uvc.user_id = u.id
LEFT JOIN user_tags ut ON ut.user_id = u.id
LEFT JOIN user_postlinks upk ON upk.user_id = u.id
ORDER BY u.reputation DESC
LIMIT 10
