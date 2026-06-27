WITH user_posts AS (
    SELECT
        u.id AS user_id,
        COUNT(DISTINCT p.id) AS post_count,
        COALESCE(SUM(p.score), 0) AS total_post_score,
        COALESCE(SUM(p.answercount), 0) AS total_answer_count,
        COALESCE(SUM(p.viewcount), 0) AS total_view_count
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    GROUP BY u.id
),
user_votes_cast AS (
    SELECT
        u.id AS user_id,
        COUNT(DISTINCT v.id) AS votes_cast_count,
        COALESCE(SUM(v.bountyamount), 0) AS total_bounty_cast
    FROM users u
    LEFT JOIN votes v
        ON v.userid = u.id
    GROUP BY u.id
),
user_votes_received AS (
    SELECT
        u.id AS user_id,
        COUNT(DISTINCT v.id) AS votes_received_count,
        COALESCE(SUM(v.bountyamount), 0) AS total_bounty_received
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    LEFT JOIN votes v
        ON v.postid = p.id
    GROUP BY u.id
),
user_links_source AS (
    SELECT
        u.id AS user_id,
        COUNT(DISTINCT pl.id) AS link_source_count
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    LEFT JOIN postlinks pl
        ON pl.postid = p.id
    GROUP BY u.id
),
user_links_target AS (
    SELECT
        u.id AS user_id,
        COUNT(DISTINCT pl.id) AS link_target_count
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    LEFT JOIN postlinks pl
        ON pl.relatedpostid = p.id
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
    u.id AS user_id,
    u.reputation,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.total_post_score, 0) AS total_post_score,
    COALESCE(up.total_answer_count, 0) AS total_answer_count,
    COALESCE(up.total_view_count, 0) AS total_view_count,
    COALESCE(uvc.votes_cast_count, 0) AS votes_cast_count,
    COALESCE(uvc.total_bounty_cast, 0) AS total_bounty_cast,
    COALESCE(uvr.votes_received_count, 0) AS votes_received_count,
    COALESCE(uvr.total_bounty_received, 0) AS total_bounty_received,
    COALESCE(uls.link_source_count, 0) AS link_source_count,
    COALESCE(ult.link_target_count, 0) AS link_target_count,
    COALESCE(ut.tag_count, 0) AS tag_count
FROM users u
LEFT JOIN user_posts up
    ON up.user_id = u.id
LEFT JOIN user_votes_cast uvc
    ON uvc.user_id = u.id
LEFT JOIN user_votes_received uvr
    ON uvr.user_id = u.id
LEFT JOIN user_links_source uls
    ON uls.user_id = u.id
LEFT JOIN user_links_target ult
    ON ult.user_id = u.id
LEFT JOIN user_tags ut
    ON ut.user_id = u.id
ORDER BY total_post_score DESC
LIMIT 100
