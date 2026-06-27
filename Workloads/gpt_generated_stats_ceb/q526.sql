WITH
    user_posts AS (
        SELECT
            owneruserid AS userid,
            COUNT(*) AS post_count,
            COALESCE(SUM(score), 0) AS total_score,
            COALESCE(SUM(viewcount), 0) AS total_views,
            COALESCE(SUM(favoritecount), 0) AS total_favorites
        FROM posts
        GROUP BY owneruserid
    ),
    user_comments AS (
        SELECT
            userid,
            COUNT(*) AS comment_count
        FROM comments
        GROUP BY userid
    ),
    user_votes AS (
        SELECT
            userid,
            COUNT(*) AS vote_cast_count
        FROM votes
        GROUP BY userid
    ),
    user_badges AS (
        SELECT
            userid,
            COUNT(*) AS badge_count
        FROM badges
        GROUP BY userid
    ),
    user_edits AS (
        SELECT
            lasteditoruserid AS userid,
            COUNT(DISTINCT id) AS edited_posts_count
        FROM posts
        GROUP BY lasteditoruserid
    ),
    user_posthistory AS (
        SELECT
            userid,
            COUNT(*) AS posthistory_count
        FROM posthistory
        GROUP BY userid
    ),
    user_tags AS (
        SELECT
            p.owneruserid AS userid,
            COUNT(*) AS tag_association_count,
            COALESCE(SUM(t."count"), 0) AS tag_total_count
        FROM posts p
        JOIN tags t ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    COALESCE(p.post_count, 0) AS post_count,
    COALESCE(p.total_score, 0) AS total_score,
    COALESCE(p.total_views, 0) AS total_views,
    COALESCE(p.total_favorites, 0) AS total_favorites,
    COALESCE(c.comment_count, 0) AS comment_count,
    COALESCE(v.vote_cast_count, 0) AS vote_cast_count,
    COALESCE(b.badge_count, 0) AS badge_count,
    COALESCE(e.edited_posts_count, 0) AS edited_posts_count,
    COALESCE(h.posthistory_count, 0) AS posthistory_count,
    COALESCE(tg.tag_association_count, 0) AS tag_association_count,
    COALESCE(tg.tag_total_count, 0) AS tag_total_count,
    (
        COALESCE(p.post_count, 0) +
        COALESCE(c.comment_count, 0) +
        COALESCE(v.vote_cast_count, 0) +
        COALESCE(b.badge_count, 0) +
        COALESCE(e.edited_posts_count, 0) +
        COALESCE(h.posthistory_count, 0) +
        COALESCE(tg.tag_association_count, 0)
    ) AS total_activity
FROM users u
LEFT JOIN user_posts p ON u.id = p.userid
LEFT JOIN user_comments c ON u.id = c.userid
LEFT JOIN user_votes v ON u.id = v.userid
LEFT JOIN user_badges b ON u.id = b.userid
LEFT JOIN user_edits e ON u.id = e.userid
LEFT JOIN user_posthistory h ON u.id = h.userid
LEFT JOIN user_tags tg ON u.id = tg.userid
ORDER BY total_activity DESC
LIMIT 10
