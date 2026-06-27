WITH user_posts AS (
    SELECT
        u.id AS user_id,
        u.reputation,
        COUNT(p.id) AS post_count,
        SUM(p.score) AS total_post_score,
        AVG(p.score) AS avg_post_score,
        SUM(p.viewcount) AS total_post_views,
        SUM(p.answercount) AS total_answers,
        SUM(p.commentcount) AS total_comments_on_posts,
        SUM(p.favoritecount) AS total_favorites
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    GROUP BY u.id, u.reputation
),
user_comments AS (
    SELECT
        u.id AS user_id,
        COUNT(c.id) AS comment_made_count
    FROM users u
    LEFT JOIN comments c
        ON c.userid = u.id
    GROUP BY u.id
),
user_comments_received AS (
    SELECT
        u.id AS user_id,
        COUNT(c.id) AS comment_received_count
    FROM users u
    JOIN posts p
        ON p.owneruserid = u.id
    LEFT JOIN comments c
        ON c.postid = p.id
    GROUP BY u.id
),
user_votes_cast AS (
    SELECT
        u.id AS user_id,
        COUNT(v.id) AS votes_cast_count,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvotes_cast,
        SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvotes_cast
    FROM users u
    LEFT JOIN votes v
        ON v.userid = u.id
    GROUP BY u.id
),
user_votes_received AS (
    SELECT
        u.id AS user_id,
        COUNT(v.id) AS votes_received_count,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvotes_received,
        SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvotes_received
    FROM users u
    JOIN posts p
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
user_edits AS (
    SELECT
        u.id AS user_id,
        COUNT(ph.id) AS edit_count
    FROM users u
    LEFT JOIN posthistory ph
        ON ph.userid = u.id
    LEFT JOIN posts p
        ON p.id = ph.posthistorytypeid
    GROUP BY u.id
),
user_last_edits AS (
    SELECT
        u.id AS user_id,
        COUNT(p.id) AS last_edit_count
    FROM users u
    LEFT JOIN posts p
        ON p.lasteditoruserid = u.id
    GROUP BY u.id
)
SELECT
    up.user_id,
    up.reputation,
    up.post_count,
    up.total_post_score,
    up.avg_post_score,
    up.total_post_views,
    up.total_answers,
    up.total_comments_on_posts,
    up.total_favorites,
    uc.comment_made_count,
    ucr.comment_received_count,
    uv.votes_cast_count,
    uv.upvotes_cast,
    uv.downvotes_cast,
    uvr.votes_received_count,
    uvr.upvotes_received,
    uvr.downvotes_received,
    ub.badge_count,
    ue.edit_count,
    ul.last_edit_count
FROM user_posts up
LEFT JOIN user_comments uc
    ON uc.user_id = up.user_id
LEFT JOIN user_comments_received ucr
    ON ucr.user_id = up.user_id
LEFT JOIN user_votes_cast uv
    ON uv.user_id = up.user_id
LEFT JOIN user_votes_received uvr
    ON uvr.user_id = up.user_id
LEFT JOIN user_badges ub
    ON ub.user_id = up.user_id
LEFT JOIN user_edits ue
    ON ue.user_id = up.user_id
LEFT JOIN user_last_edits ul
    ON ul.user_id = up.user_id
ORDER BY up.reputation DESC
LIMIT 100
