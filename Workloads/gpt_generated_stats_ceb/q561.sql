WITH post_stats AS (
    SELECT
        p.owneruserid,
        COUNT(*) AS post_count,
        AVG(p.score) AS avg_post_score,
        SUM(p.viewcount) AS total_views,
        SUM(p.favoritecount) AS total_favorites
    FROM posts p
    GROUP BY p.owneruserid
),
comment_stats AS (
    SELECT
        c.userid,
        COUNT(*) AS comment_count,
        AVG(c.score) AS avg_comment_score,
        SUM(c.score) AS total_comment_score
    FROM comments c
    GROUP BY c.userid
),
edit_stats AS (
    SELECT
        p.lasteditoruserid,
        COUNT(*) AS edit_count
    FROM posts p
    WHERE p.lasteditoruserid IS NOT NULL
    GROUP BY p.lasteditoruserid
)
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate AS user_creationdate,
    COALESCE(ps.post_count, 0) AS post_count,
    COALESCE(ps.avg_post_score, 0) AS avg_post_score,
    COALESCE(ps.total_views, 0) AS total_views,
    COALESCE(ps.total_favorites, 0) AS total_favorites,
    COALESCE(cs.comment_count, 0) AS comment_count,
    COALESCE(cs.avg_comment_score, 0) AS avg_comment_score,
    COALESCE(cs.total_comment_score, 0) AS total_comment_score,
    COALESCE(es.edit_count, 0) AS edit_count,
    (COALESCE(ps.post_count, 0) + COALESCE(cs.comment_count, 0) + COALESCE(es.edit_count, 0)) AS total_activity
FROM users u
LEFT JOIN post_stats ps ON ps.owneruserid = u.id
LEFT JOIN comment_stats cs ON cs.userid = u.id
LEFT JOIN edit_stats es ON es.lasteditoruserid = u.id
ORDER BY total_activity DESC
LIMIT 10
