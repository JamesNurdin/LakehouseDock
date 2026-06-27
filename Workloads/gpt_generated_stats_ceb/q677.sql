WITH
    user_posts AS (
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
    user_votes_cast AS (
        SELECT
            v.userid AS user_id,
            COUNT(*) AS vote_cast_count
        FROM votes v
        GROUP BY v.userid
    ),
    user_votes_received AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS votes_received_count
        FROM votes v
        JOIN posts p ON v.postid = p.id
        GROUP BY p.owneruserid
    ),
    user_badges AS (
        SELECT
            b.userid AS user_id,
            COUNT(*) AS badge_count
        FROM badges b
        GROUP BY b.userid
    ),
    user_tag_excerpts AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(DISTINCT t.id) AS tag_excerpt_count
        FROM tags t
        JOIN posts p ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    ),
    user_edits AS (
        SELECT
            p.lasteditoruserid AS user_id,
            COUNT(*) AS edit_count
        FROM posts p
        GROUP BY p.lasteditoruserid
    ),
    user_posthistory AS (
        SELECT
            ph.userid AS user_id,
            COUNT(*) AS posthistory_count
        FROM posthistory ph
        GROUP BY ph.userid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.total_score, 0) AS total_post_score,
    COALESCE(up.avg_score, 0) AS avg_post_score,
    COALESCE(up.total_views, 0) AS total_post_views,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uvc.vote_cast_count, 0) AS vote_cast_count,
    COALESCE(uvr.votes_received_count, 0) AS votes_received_count,
    COALESCE(ub.badge_count, 0) AS badge_count,
    COALESCE(ute.tag_excerpt_count, 0) AS tag_excerpt_count,
    COALESCE(ue.edit_count, 0) AS edit_count,
    COALESCE(uph.posthistory_count, 0) AS posthistory_count
FROM users u
LEFT JOIN user_posts up ON up.user_id = u.id
LEFT JOIN user_comments uc ON uc.user_id = u.id
LEFT JOIN user_votes_cast uvc ON uvc.user_id = u.id
LEFT JOIN user_votes_received uvr ON uvr.user_id = u.id
LEFT JOIN user_badges ub ON ub.user_id = u.id
LEFT JOIN user_tag_excerpts ute ON ute.user_id = u.id
LEFT JOIN user_edits ue ON ue.user_id = u.id
LEFT JOIN user_posthistory uph ON uph.user_id = u.id
WHERE u.reputation > 0
ORDER BY total_post_score DESC
LIMIT 100
