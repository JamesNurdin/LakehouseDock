WITH user_posts AS (
    SELECT
        u.id AS user_id,
        u.reputation,
        u.creationdate AS user_creationdate,
        COUNT(p.id) AS post_count,
        COALESCE(SUM(p.score), 0) AS total_post_score,
        AVG(p.score) AS avg_post_score,
        MIN(p.creationdate) AS earliest_post_date
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    GROUP BY u.id, u.reputation, u.creationdate
),
user_comments AS (
    SELECT
        u.id AS user_id,
        COUNT(c.id) AS comment_count,
        COALESCE(SUM(c.score), 0) AS total_comment_score,
        AVG(c.score) AS avg_comment_score
    FROM users u
    LEFT JOIN comments c
        ON c.userid = u.id
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
user_votes_received AS (
    SELECT
        u.id AS user_id,
        COUNT(v.id) AS votes_received_count
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    LEFT JOIN votes v
        ON v.postid = p.id
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
user_tags AS (
    SELECT
        u.id AS user_id,
        COUNT(DISTINCT t.id) AS distinct_tag_count
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    LEFT JOIN tags t
        ON t.excerptpostid = p.id
    GROUP BY u.id
),
user_posthistory AS (
    SELECT
        u.id AS user_id,
        COUNT(ph.id) AS posthistory_count
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    LEFT JOIN posthistory ph
        ON ph.posthistorytypeid = p.id
    GROUP BY u.id
),
user_links_out AS (
    SELECT
        u.id AS user_id,
        COUNT(pl.id) AS outgoing_link_count
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    LEFT JOIN postlinks pl
        ON pl.postid = p.id
    GROUP BY u.id
),
user_links_in AS (
    SELECT
        u.id AS user_id,
        COUNT(pl.id) AS incoming_link_count
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    LEFT JOIN postlinks pl
        ON pl.relatedpostid = p.id
    GROUP BY u.id
)
SELECT
    up.user_id,
    up.reputation,
    up.user_creationdate,
    up.post_count,
    up.total_post_score,
    up.avg_post_score,
    up.earliest_post_date,
    uc.comment_count,
    uc.total_comment_score,
    uc.avg_comment_score,
    uv_cast.votes_cast_count,
    uv_received.votes_received_count,
    ub.badge_count,
    ut.distinct_tag_count,
    uph.posthistory_count,
    ul_out.outgoing_link_count,
    ul_in.incoming_link_count,
    RANK() OVER (ORDER BY up.total_post_score DESC) AS post_score_rank
FROM user_posts up
LEFT JOIN user_comments uc
    ON uc.user_id = up.user_id
LEFT JOIN user_votes_cast uv_cast
    ON uv_cast.user_id = up.user_id
LEFT JOIN user_votes_received uv_received
    ON uv_received.user_id = up.user_id
LEFT JOIN user_badges ub
    ON ub.user_id = up.user_id
LEFT JOIN user_tags ut
    ON ut.user_id = up.user_id
LEFT JOIN user_posthistory uph
    ON uph.user_id = up.user_id
LEFT JOIN user_links_out ul_out
    ON ul_out.user_id = up.user_id
LEFT JOIN user_links_in ul_in
    ON ul_in.user_id = up.user_id
ORDER BY up.total_post_score DESC
LIMIT 10
