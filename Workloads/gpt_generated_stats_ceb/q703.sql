WITH user_info AS (
    SELECT
        id,
        reputation,
        creationdate,
        views,
        upvotes,
        downvotes
    FROM users
),
badge_counts AS (
    SELECT
        userid,
        COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
),
post_metrics AS (
    SELECT
        owneruserid AS userid,
        COUNT(*) AS post_count,
        AVG(score) AS avg_post_score,
        SUM(viewcount) AS total_post_views
    FROM posts
    GROUP BY owneruserid
),
comment_counts AS (
    SELECT
        userid,
        COUNT(*) AS comment_count
    FROM comments
    GROUP BY userid
),
votes_cast_counts AS (
    SELECT
        userid,
        COUNT(*) AS votes_cast_count
    FROM votes
    GROUP BY userid
),
votes_received_counts AS (
    SELECT
        p.owneruserid AS userid,
        COUNT(*) AS votes_received_count
    FROM posts p
    JOIN votes v ON v.postid = p.id
    GROUP BY p.owneruserid
)
SELECT
    u.id,
    u.reputation,
    u.creationdate,
    u.views,
    u.upvotes,
    u.downvotes,
    COALESCE(b.badge_count, 0) AS badge_count,
    COALESCE(p.post_count, 0) AS post_count,
    COALESCE(p.avg_post_score, 0) AS avg_post_score,
    COALESCE(p.total_post_views, 0) AS total_post_views,
    COALESCE(c.comment_count, 0) AS comment_count,
    COALESCE(vc.votes_cast_count, 0) AS votes_cast_count,
    COALESCE(vr.votes_received_count, 0) AS votes_received_count
FROM user_info u
LEFT JOIN badge_counts b ON b.userid = u.id
LEFT JOIN post_metrics p ON p.userid = u.id
LEFT JOIN comment_counts c ON c.userid = u.id
LEFT JOIN votes_cast_counts vc ON vc.userid = u.id
LEFT JOIN votes_received_counts vr ON vr.userid = u.id
ORDER BY u.reputation DESC
LIMIT 10
