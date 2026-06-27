WITH user_posts AS (
    SELECT
        p.owneruserid AS userid,
        COUNT(*) AS post_count,
        SUM(p.score) AS post_score_sum,
        AVG(p.score) AS post_score_avg
    FROM posts p
    GROUP BY p.owneruserid
),
user_comments_made AS (
    SELECT
        c.userid AS userid,
        COUNT(*) AS comment_made_count,
        SUM(c.score) AS comment_made_score_sum
    FROM comments c
    GROUP BY c.userid
),
comments_received AS (
    SELECT
        p.owneruserid AS userid,
        COUNT(c.id) AS comment_received_count,
        SUM(c.score) AS comment_received_score_sum
    FROM posts p
    LEFT JOIN comments c
        ON c.postid = p.id
    GROUP BY p.owneruserid
),
tags_per_user AS (
    SELECT
        p.owneruserid AS userid,
        COUNT(t.id) AS tag_count,
        COALESCE(SUM(t.count), 0) AS tag_usage_sum
    FROM posts p
    LEFT JOIN tags t
        ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
),
edit_counts AS (
    SELECT
        p.lasteditoruserid AS userid,
        COUNT(*) AS edit_count
    FROM posts p
    WHERE p.lasteditoruserid IS NOT NULL
    GROUP BY p.lasteditoruserid
)
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.post_score_sum, 0) AS post_score_sum,
    COALESCE(up.post_score_avg, 0) AS post_score_avg,
    COALESCE(cm.comment_made_count, 0) AS comment_made_count,
    COALESCE(cm.comment_made_score_sum, 0) AS comment_made_score_sum,
    COALESCE(cr.comment_received_count, 0) AS comment_received_count,
    COALESCE(cr.comment_received_score_sum, 0) AS comment_received_score_sum,
    COALESCE(tg.tag_count, 0) AS tag_count,
    COALESCE(tg.tag_usage_sum, 0) AS tag_usage_sum,
    COALESCE(ec.edit_count, 0) AS edit_count
FROM users u
LEFT JOIN user_posts up
    ON up.userid = u.id
LEFT JOIN user_comments_made cm
    ON cm.userid = u.id
LEFT JOIN comments_received cr
    ON cr.userid = u.id
LEFT JOIN tags_per_user tg
    ON tg.userid = u.id
LEFT JOIN edit_counts ec
    ON ec.userid = u.id
ORDER BY u.reputation DESC, post_count DESC
LIMIT 10
