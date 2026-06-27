WITH user_posts AS (
    SELECT
        u.id AS user_id,
        u.reputation,
        COUNT(p.id) AS posts_owned,
        SUM(p.score) AS posts_score_sum,
        AVG(p.score) AS posts_score_avg,
        SUM(p.viewcount) AS posts_viewcount_sum
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    GROUP BY u.id, u.reputation
),
user_edits AS (
    SELECT
        u.id AS user_id,
        COUNT(p.id) AS posts_edited
    FROM users u
    LEFT JOIN posts p ON p.lasteditoruserid = u.id
    GROUP BY u.id
),
user_votes_cast AS (
    SELECT
        u.id AS user_id,
        COUNT(v.id) AS votes_cast
    FROM users u
    LEFT JOIN votes v ON v.userid = u.id
    GROUP BY u.id
),
user_votes_received AS (
    SELECT
        u.id AS user_id,
        COUNT(v.id) AS votes_received
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    LEFT JOIN votes v ON v.postid = p.id
    GROUP BY u.id
),
user_posthistory AS (
    SELECT
        u.id AS user_id,
        COUNT(ph.id) AS posthistory_events
    FROM users u
    LEFT JOIN posthistory ph ON ph.userid = u.id
    GROUP BY u.id
),
user_tags AS (
    SELECT
        u.id AS user_id,
        COUNT(DISTINCT t.id) AS distinct_tags_excerpts_owned
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    LEFT JOIN tags t ON t.excerptpostid = p.id
    GROUP BY u.id
),
user_postlinks AS (
    SELECT
        u.id AS user_id,
        COUNT(pl.id) AS postlinks_owned_posts,
        COUNT(DISTINCT pl.relatedpostid) AS distinct_related_posts
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    LEFT JOIN postlinks pl ON pl.postid = p.id
    GROUP BY u.id
)
SELECT
    up.user_id,
    up.reputation,
    up.posts_owned,
    up.posts_score_sum,
    up.posts_score_avg,
    up.posts_viewcount_sum,
    ue.posts_edited,
    uv.votes_cast,
    urr.votes_received,
    uph.posthistory_events,
    ut.distinct_tags_excerpts_owned,
    upl.postlinks_owned_posts,
    upl.distinct_related_posts
FROM user_posts up
LEFT JOIN user_edits ue ON ue.user_id = up.user_id
LEFT JOIN user_votes_cast uv ON uv.user_id = up.user_id
LEFT JOIN user_votes_received urr ON urr.user_id = up.user_id
LEFT JOIN user_posthistory uph ON uph.user_id = up.user_id
LEFT JOIN user_tags ut ON ut.user_id = up.user_id
LEFT JOIN user_postlinks upl ON upl.user_id = up.user_id
ORDER BY up.posts_owned DESC
LIMIT 100
