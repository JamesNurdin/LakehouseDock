WITH
    user_posts AS (
        SELECT
            p.owneruserid,
            COUNT(*) AS post_count,
            SUM(p.score) AS post_score_sum
        FROM posts p
        GROUP BY p.owneruserid
    ),
    user_edited_posts AS (
        SELECT
            p.lasteditoruserid,
            COUNT(*) AS edited_post_count
        FROM posts p
        GROUP BY p.lasteditoruserid
    ),
    user_comments AS (
        SELECT
            c.userid,
            COUNT(*) AS comment_count,
            SUM(c.score) AS comment_score_sum
        FROM comments c
        GROUP BY c.userid
    ),
    user_votes_cast AS (
        SELECT
            v.userid,
            COUNT(*) AS votes_cast_count
        FROM votes v
        GROUP BY v.userid
    ),
    user_votes_received AS (
        SELECT
            p.owneruserid,
            COUNT(*) AS votes_received_count
        FROM votes v
        JOIN posts p ON v.postid = p.id
        GROUP BY p.owneruserid
    ),
    user_badges AS (
        SELECT
            b.userid,
            COUNT(*) AS badge_count
        FROM badges b
        GROUP BY b.userid
    ),
    user_tag_excerpts AS (
        SELECT
            p.owneruserid,
            COUNT(*) AS tag_excerpt_count
        FROM tags t
        JOIN posts p ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    ),
    user_posthistory AS (
        SELECT
            ph.userid,
            COUNT(*) AS posthistory_count
        FROM posthistory ph
        GROUP BY ph.userid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.post_score_sum, 0) AS post_score_sum,
    COALESCE(uep.edited_post_count, 0) AS edited_post_count,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uc.comment_score_sum, 0) AS comment_score_sum,
    COALESCE(uvc.votes_cast_count, 0) AS votes_cast_count,
    COALESCE(uvr.votes_received_count, 0) AS votes_received_count,
    COALESCE(ub.badge_count, 0) AS badge_count,
    COALESCE(ut.tag_excerpt_count, 0) AS tag_excerpt_count,
    COALESCE(uph.posthistory_count, 0) AS posthistory_count
FROM users u
LEFT JOIN user_posts up ON up.owneruserid = u.id
LEFT JOIN user_edited_posts uep ON uep.lasteditoruserid = u.id
LEFT JOIN user_comments uc ON uc.userid = u.id
LEFT JOIN user_votes_cast uvc ON uvc.userid = u.id
LEFT JOIN user_votes_received uvr ON uvr.owneruserid = u.id
LEFT JOIN user_badges ub ON ub.userid = u.id
LEFT JOIN user_tag_excerpts ut ON ut.owneruserid = u.id
LEFT JOIN user_posthistory uph ON uph.userid = u.id
ORDER BY u.reputation DESC
LIMIT 20
