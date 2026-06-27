WITH user_posts AS (
    SELECT
        u.id AS user_id,
        u.reputation,
        u.creationdate,
        u.views,
        u.upvotes,
        u.downvotes,
        COUNT(p.id) AS post_count,
        SUM(p.score) AS total_score,
        AVG(p.score) AS avg_score,
        SUM(p.viewcount) AS total_viewcount,
        SUM(p.answercount) AS total_answercount,
        SUM(p.commentcount) AS total_commentcount,
        SUM(p.favoritecount) AS total_favoritecount
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    GROUP BY u.id, u.reputation, u.creationdate, u.views, u.upvotes, u.downvotes
),
user_edits AS (
    SELECT
        u.id AS user_id,
        COUNT(p.id) AS edited_post_count
    FROM users u
    LEFT JOIN posts p ON p.lasteditoruserid = u.id
    GROUP BY u.id
),
user_votes_cast AS (
    SELECT
        u.id AS user_id,
        COUNT(v.id) AS votes_cast,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS up_votes_cast,
        SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS down_votes_cast
    FROM users u
    LEFT JOIN votes v ON v.userid = u.id
    GROUP BY u.id
),
user_votes_received AS (
    SELECT
        u.id AS user_id,
        COUNT(v.id) AS votes_received,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS up_votes_received,
        SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS down_votes_received
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    LEFT JOIN votes v ON v.postid = p.id
    GROUP BY u.id
),
user_posthistory AS (
    SELECT
        u.id AS user_id,
        COUNT(ph.id) AS posthistory_entries,
        COUNT(DISTINCT ph.postid) AS distinct_posts_edited
    FROM users u
    LEFT JOIN posthistory ph ON ph.userid = u.id
    GROUP BY u.id
)
SELECT
    up.user_id,
    up.reputation,
    up.creationdate,
    up.views,
    up.upvotes,
    up.downvotes,
    up.post_count,
    up.total_score,
    up.avg_score,
    up.total_viewcount,
    up.total_answercount,
    up.total_commentcount,
    up.total_favoritecount,
    ue.edited_post_count,
    uv_cast.votes_cast,
    uv_cast.up_votes_cast,
    uv_cast.down_votes_cast,
    uv_received.votes_received,
    uv_received.up_votes_received,
    uv_received.down_votes_received,
    uh.posthistory_entries,
    uh.distinct_posts_edited
FROM user_posts up
LEFT JOIN user_edits ue ON ue.user_id = up.user_id
LEFT JOIN user_votes_cast uv_cast ON uv_cast.user_id = up.user_id
LEFT JOIN user_votes_received uv_received ON uv_received.user_id = up.user_id
LEFT JOIN user_posthistory uh ON uh.user_id = up.user_id
ORDER BY up.reputation DESC
LIMIT 100
