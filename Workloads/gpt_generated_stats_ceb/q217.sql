WITH
    user_posts AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS post_count,
            SUM(p.score) AS post_score_sum,
            SUM(p.viewcount) AS post_view_sum
        FROM posts p
        GROUP BY p.owneruserid
    ),
    user_edited_posts AS (
        SELECT
            p.lasteditoruserid AS user_id,
            COUNT(*) AS edited_post_count
        FROM posts p
        GROUP BY p.lasteditoruserid
    ),
    user_comments AS (
        SELECT
            c.userid AS user_id,
            COUNT(*) AS comment_count,
            SUM(c.score) AS comment_score_sum
        FROM comments c
        GROUP BY c.userid
    ),
    user_votes AS (
        SELECT
            v.userid AS user_id,
            COUNT(*) AS vote_count
        FROM votes v
        GROUP BY v.userid
    ),
    user_badges AS (
        SELECT
            b.userid AS user_id,
            COUNT(*) AS badge_count
        FROM badges b
        GROUP BY b.userid
    ),
    user_posthistory AS (
        SELECT
            ph.userid AS user_id,
            COUNT(*) AS posthistory_count
        FROM posthistory ph
        GROUP BY ph.userid
    ),
    user_tags AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(DISTINCT t.id) AS tag_count
        FROM posts p
        JOIN tags t ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(p.post_count, 0) AS post_count,
    COALESCE(p.post_score_sum, 0) AS post_score_sum,
    COALESCE(p.post_view_sum, 0) AS post_view_sum,
    COALESCE(e.edited_post_count, 0) AS edited_post_count,
    COALESCE(c.comment_count, 0) AS comment_count,
    COALESCE(c.comment_score_sum, 0) AS comment_score_sum,
    COALESCE(v.vote_count, 0) AS vote_count,
    COALESCE(b.badge_count, 0) AS badge_count,
    COALESCE(ph.posthistory_count, 0) AS posthistory_count,
    COALESCE(t.tag_count, 0) AS tag_count
FROM users u
LEFT JOIN user_posts p ON u.id = p.user_id
LEFT JOIN user_edited_posts e ON u.id = e.user_id
LEFT JOIN user_comments c ON u.id = c.user_id
LEFT JOIN user_votes v ON u.id = v.user_id
LEFT JOIN user_badges b ON u.id = b.user_id
LEFT JOIN user_posthistory ph ON u.id = ph.user_id
LEFT JOIN user_tags t ON u.id = t.user_id
ORDER BY u.reputation DESC
LIMIT 100
