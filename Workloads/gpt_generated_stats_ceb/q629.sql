WITH
    user_posts AS (
        SELECT
            u.id AS user_id,
            COUNT(p.id) AS post_count,
            SUM(p.score) AS total_post_score,
            AVG(p.score) AS avg_post_score,
            SUM(p.viewcount) AS total_view_count,
            SUM(p.favoritecount) AS total_favorite_count
        FROM users u
        LEFT JOIN posts p ON p.owneruserid = u.id
        GROUP BY u.id
    ),
    user_comments AS (
        SELECT
            u.id AS user_id,
            COUNT(c.id) AS comment_count,
            SUM(c.score) AS total_comment_score
        FROM users u
        LEFT JOIN comments c ON c.userid = u.id
        GROUP BY u.id
    ),
    user_votes_cast AS (
        SELECT
            u.id AS user_id,
            COUNT(v.id) AS vote_cast_count,
            SUM(COALESCE(v.bountyamount, 0)) AS total_bounty_given
        FROM users u
        LEFT JOIN votes v ON v.userid = u.id
        GROUP BY u.id
    ),
    user_votes_received AS (
        SELECT
            u.id AS user_id,
            COUNT(v.id) AS vote_received_count,
            SUM(COALESCE(v.bountyamount, 0)) AS total_bounty_received
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
    user_edits AS (
        SELECT
            u.id AS user_id,
            COUNT(p.id) AS edit_count
        FROM users u
        LEFT JOIN posts p ON p.lasteditoruserid = u.id
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
    user_tags AS (
        SELECT
            u.id AS user_id,
            COUNT(t.id) AS tag_count
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
    u.id AS user_id,
    u.reputation,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.total_post_score, 0) AS total_post_score,
    COALESCE(up.avg_post_score, 0) AS avg_post_score,
    COALESCE(up.total_view_count, 0) AS total_view_count,
    COALESCE(up.total_favorite_count, 0) AS total_favorite_count,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uc.total_comment_score, 0) AS total_comment_score,
    COALESCE(uvc.vote_cast_count, 0) AS vote_cast_count,
    COALESCE(uvc.total_bounty_given, 0) AS total_bounty_given,
    COALESCE(uvr.vote_received_count, 0) AS vote_received_count,
    COALESCE(uvr.total_bounty_received, 0) AS total_bounty_received,
    COALESCE(ub.badge_count, 0) AS badge_count,
    COALESCE(ue.edit_count, 0) AS edit_count,
    COALESCE(uph.posthistory_count, 0) AS posthistory_count,
    COALESCE(ut.tag_count, 0) AS tag_count,
    COALESCE(upL.postlink_count, 0) AS postlink_count
FROM users u
LEFT JOIN user_posts up ON up.user_id = u.id
LEFT JOIN user_comments uc ON uc.user_id = u.id
LEFT JOIN user_votes_cast uvc ON uvc.user_id = u.id
LEFT JOIN user_votes_received uvr ON uvr.user_id = u.id
LEFT JOIN user_badges ub ON ub.user_id = u.id
LEFT JOIN user_edits ue ON ue.user_id = u.id
LEFT JOIN user_posthistory uph ON uph.user_id = u.id
LEFT JOIN user_tags ut ON ut.user_id = u.id
LEFT JOIN user_postlinks upL ON upL.user_id = u.id
ORDER BY total_post_score DESC
LIMIT 100
