WITH
    owned_posts AS (
        SELECT
            owneruserid AS user_id,
            COUNT(*) AS owned_posts,
            SUM(score) AS total_owned_post_score,
            AVG(viewcount) AS avg_owned_post_viewcount
        FROM posts
        GROUP BY owneruserid
    ),
    edited_posts AS (
        SELECT
            lasteditoruserid AS user_id,
            COUNT(*) AS edited_posts
        FROM posts
        GROUP BY lasteditoruserid
    ),
    comments_made AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS comments_made
        FROM comments
        GROUP BY userid
    ),
    votes_cast AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS votes_cast
        FROM votes
        GROUP BY userid
    ),
    badges_earned AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS badges_earned
        FROM badges
        GROUP BY userid
    ),
    post_history_entries AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS post_history_entries
        FROM posthistory
        GROUP BY userid
    ),
    tags_on_owned_posts AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(DISTINCT t.id) AS tags_on_owned_posts
        FROM tags t
        JOIN posts p ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(op.owned_posts, 0) AS owned_posts,
    COALESCE(ep.edited_posts, 0) AS edited_posts,
    COALESCE(cm.comments_made, 0) AS comments_made,
    COALESCE(vc.votes_cast, 0) AS votes_cast,
    COALESCE(be.badges_earned, 0) AS badges_earned,
    COALESCE(ph.post_history_entries, 0) AS post_history_entries,
    COALESCE(tp.tags_on_owned_posts, 0) AS tags_on_owned_posts,
    COALESCE(op.total_owned_post_score, 0) AS total_owned_post_score,
    COALESCE(op.avg_owned_post_viewcount, 0) AS avg_owned_post_viewcount,
    (
        COALESCE(op.owned_posts, 0) +
        COALESCE(ep.edited_posts, 0) +
        COALESCE(cm.comments_made, 0) +
        COALESCE(vc.votes_cast, 0) +
        COALESCE(be.badges_earned, 0) +
        COALESCE(ph.post_history_entries, 0)
    ) AS total_activity
FROM users u
LEFT JOIN owned_posts op ON op.user_id = u.id
LEFT JOIN edited_posts ep ON ep.user_id = u.id
LEFT JOIN comments_made cm ON cm.user_id = u.id
LEFT JOIN votes_cast vc ON vc.user_id = u.id
LEFT JOIN badges_earned be ON be.user_id = u.id
LEFT JOIN post_history_entries ph ON ph.user_id = u.id
LEFT JOIN tags_on_owned_posts tp ON tp.user_id = u.id
ORDER BY total_activity DESC
LIMIT 100
