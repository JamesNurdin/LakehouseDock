WITH
    user_posts AS (
        SELECT
            u.id AS user_id,
            u.reputation,
            COUNT(p.id) AS post_count,
            COALESCE(SUM(p.score), 0) AS total_post_score,
            COALESCE(AVG(p.viewcount), 0) AS avg_post_viewcount,
            COALESCE(SUM(p.favoritecount), 0) AS total_favorite_count
        FROM users u
        LEFT JOIN posts p ON p.owneruserid = u.id
        GROUP BY u.id, u.reputation
    ),
    user_comments AS (
        SELECT
            u.id AS user_id,
            COUNT(c.id) AS comment_count,
            COALESCE(SUM(c.score), 0) AS total_comment_score
        FROM users u
        LEFT JOIN comments c ON c.userid = u.id
        GROUP BY u.id
    ),
    user_votes_cast AS (
        SELECT
            u.id AS user_id,
            COUNT(v.id) AS vote_cast_count
        FROM users u
        LEFT JOIN votes v ON v.userid = u.id
        GROUP BY u.id
    ),
    user_votes_received AS (
        SELECT
            u.id AS user_id,
            COUNT(v.id) AS post_votes_received
        FROM users u
        LEFT JOIN posts p ON p.owneruserid = u.id
        LEFT JOIN votes v ON v.postid = p.id
        GROUP BY u.id
    ),
    user_badges AS (
        SELECT
            u.id AS user_id,
            COUNT(b.id) AS badge_count
        FROM users u
        LEFT JOIN badges b ON b.userid = u.id
        GROUP BY u.id
    ),
    user_posthistory AS (
        SELECT
            u.id AS user_id,
            COUNT(ph.id) AS posthistory_count
        FROM users u
        LEFT JOIN posthistory ph ON ph.userid = u.id
        GROUP BY u.id
    ),
    user_edits AS (
        SELECT
            u.id AS user_id,
            COUNT(p.id) AS edited_post_count
        FROM users u
        LEFT JOIN posts p ON p.lasteditoruserid = u.id
        GROUP BY u.id
    ),
    user_tags AS (
        SELECT
            u.id AS user_id,
            COUNT(DISTINCT t.id) AS distinct_tag_excerpt_count
        FROM users u
        LEFT JOIN posts p ON p.owneruserid = u.id
        LEFT JOIN tags t ON t.excerptpostid = p.id
        GROUP BY u.id
    ),
    user_postlinks AS (
        SELECT
            u.id AS user_id,
            COUNT(pl.id) AS postlink_count
        FROM users u
        LEFT JOIN posts p ON p.owneruserid = u.id
        LEFT JOIN postlinks pl ON pl.postid = p.id
        GROUP BY u.id
    )
SELECT
    up.user_id,
    up.reputation,
    up.post_count,
    up.total_post_score,
    up.avg_post_viewcount,
    up.total_favorite_count,
    uc.comment_count,
    uc.total_comment_score,
    uv_cast.vote_cast_count,
    uv_received.post_votes_received,
    ub.badge_count,
    uph.posthistory_count,
    ue.edited_post_count,
    ut.distinct_tag_excerpt_count,
    upl.postlink_count
FROM user_posts up
LEFT JOIN user_comments uc ON uc.user_id = up.user_id
LEFT JOIN user_votes_cast uv_cast ON uv_cast.user_id = up.user_id
LEFT JOIN user_votes_received uv_received ON uv_received.user_id = up.user_id
LEFT JOIN user_badges ub ON ub.user_id = up.user_id
LEFT JOIN user_posthistory uph ON uph.user_id = up.user_id
LEFT JOIN user_edits ue ON ue.user_id = up.user_id
LEFT JOIN user_tags ut ON ut.user_id = up.user_id
LEFT JOIN user_postlinks upl ON upl.user_id = up.user_id
ORDER BY up.post_count DESC
LIMIT 100
