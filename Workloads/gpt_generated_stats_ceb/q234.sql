WITH
    user_posts AS (
        SELECT
            u.id AS user_id,
            COUNT(p.id) AS post_count,
            SUM(p.score) AS total_post_score,
            AVG(p.viewcount) AS avg_viewcount
        FROM users u
        LEFT JOIN posts p
            ON p.owneruserid = u.id
        GROUP BY u.id
    ),
    user_badges AS (
        SELECT
            u.id AS user_id,
            COUNT(b.id) AS badge_count
        FROM users u
        LEFT JOIN badges b
            ON b.userid = u.id
        GROUP BY u.id
    ),
    user_votes_cast AS (
        SELECT
            u.id AS user_id,
            COUNT(v.id) AS votes_cast_count
        FROM users u
        LEFT JOIN votes v
            ON v.userid = u.id
        GROUP BY u.id
    ),
    user_comments AS (
        SELECT
            u.id AS user_id,
            COUNT(c.id) AS comment_count
        FROM users u
        LEFT JOIN comments c
            ON c.userid = u.id
        GROUP BY u.id
    ),
    user_votes_received AS (
        SELECT
            u.id AS user_id,
            COUNT(v.id) AS votes_received_count,
            COALESCE(SUM(v.bountyamount), 0) AS total_bounty_received
        FROM users u
        LEFT JOIN posts p
            ON p.owneruserid = u.id
        LEFT JOIN votes v
            ON v.postid = p.id
        GROUP BY u.id
    ),
    user_tags AS (
        SELECT
            u.id AS user_id,
            COUNT(DISTINCT t.id) AS tag_count
        FROM users u
        LEFT JOIN posts p
            ON p.owneruserid = u.id
        LEFT JOIN tags t
            ON t.excerptpostid = p.id
        GROUP BY u.id
    )
SELECT
    u.id,
    u.reputation,
    up.post_count,
    up.total_post_score,
    up.avg_viewcount,
    ub.badge_count,
    uvc.votes_cast_count,
    uc.comment_count,
    uvrc.votes_received_count,
    uvrc.total_bounty_received,
    ut.tag_count
FROM users u
LEFT JOIN user_posts up
    ON up.user_id = u.id
LEFT JOIN user_badges ub
    ON ub.user_id = u.id
LEFT JOIN user_votes_cast uvc
    ON uvc.user_id = u.id
LEFT JOIN user_comments uc
    ON uc.user_id = u.id
LEFT JOIN user_votes_received uvrc
    ON uvrc.user_id = u.id
LEFT JOIN user_tags ut
    ON ut.user_id = u.id
ORDER BY up.total_post_score DESC
LIMIT 10
