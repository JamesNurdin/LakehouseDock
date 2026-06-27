WITH user_posts AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS post_count,
            COALESCE(SUM(p.score), 0) AS total_score,
            COALESCE(AVG(p.score), 0) AS avg_score,
            COALESCE(SUM(p.viewcount), 0) AS total_views
        FROM posts p
        GROUP BY p.owneruserid
    ),
    user_comments AS (
        SELECT
            c.userid AS user_id,
            COUNT(*) AS comment_count
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
        FROM tags t
        JOIN posts p ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.total_score, 0) AS total_post_score,
    COALESCE(up.avg_score, 0) AS avg_post_score,
    COALESCE(up.total_views, 0) AS total_post_views,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uv.vote_count, 0) AS vote_count,
    COALESCE(ub.badge_count, 0) AS badge_count,
    COALESCE(uph.posthistory_count, 0) AS posthistory_count,
    COALESCE(ut.tag_count, 0) AS tag_count
FROM users u
LEFT JOIN user_posts up      ON up.user_id = u.id
LEFT JOIN user_comments uc   ON uc.user_id = u.id
LEFT JOIN user_votes uv      ON uv.user_id = u.id
LEFT JOIN user_badges ub     ON ub.user_id = u.id
LEFT JOIN user_posthistory uph ON uph.user_id = u.id
LEFT JOIN user_tags ut       ON ut.user_id = u.id
ORDER BY total_post_score DESC
LIMIT 10
