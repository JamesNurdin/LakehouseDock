WITH user_posts AS (
    SELECT
        u.id AS user_id,
        u.reputation,
        COUNT(p.id) AS post_count,
        SUM(CASE WHEN p.posttypeid = 2 THEN 1 ELSE 0 END) AS answer_count,
        SUM(p.score) AS total_post_score,
        AVG(p.score) AS avg_post_score,
        SUM(p.viewcount) AS total_views
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    GROUP BY u.id, u.reputation
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
user_votes_cast AS (
    SELECT
        u.id AS user_id,
        COUNT(v.id) AS votes_cast_count,
        SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS upvotes_cast,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS downvotes_cast
    FROM users u
    LEFT JOIN votes v
        ON v.userid = u.id
    GROUP BY u.id
),
user_votes_received AS (
    SELECT
        u.id AS user_id,
        COUNT(v.id) AS votes_received_count,
        SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS upvotes_received,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS downvotes_received
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    LEFT JOIN votes v
        ON v.postid = p.id
    GROUP BY u.id
),
user_edits AS (
    SELECT
        u.id AS user_id,
        COUNT(ph.id) AS edit_count
    FROM users u
    LEFT JOIN posthistory ph
        ON ph.userid = u.id
    GROUP BY u.id
),
user_links AS (
    SELECT
        u.id AS user_id,
        COUNT(pl.id) AS link_count
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    LEFT JOIN postlinks pl
        ON pl.postid = p.id
    GROUP BY u.id
)
SELECT
    up.user_id,
    up.reputation,
    up.post_count,
    up.answer_count,
    up.total_post_score,
    up.avg_post_score,
    up.total_views,
    uc.comment_count,
    uv_cast.votes_cast_count,
    uv_cast.upvotes_cast,
    uv_cast.downvotes_cast,
    uv_received.votes_received_count,
    uv_received.upvotes_received,
    uv_received.downvotes_received,
    ue.edit_count,
    ul.link_count
FROM user_posts up
LEFT JOIN user_comments uc
    ON uc.user_id = up.user_id
LEFT JOIN user_votes_cast uv_cast
    ON uv_cast.user_id = up.user_id
LEFT JOIN user_votes_received uv_received
    ON uv_received.user_id = up.user_id
LEFT JOIN user_edits ue
    ON ue.user_id = up.user_id
LEFT JOIN user_links ul
    ON ul.user_id = up.user_id
ORDER BY up.total_post_score DESC
LIMIT 100
