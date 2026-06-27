WITH user_posts AS (
    SELECT
        u.id AS user_id,
        u.reputation,
        COUNT(p.id) AS post_cnt,
        SUM(p.viewcount) AS total_views,
        AVG(p.score) AS avg_post_score,
        SUM(p.answercount) AS total_answers,
        SUM(p.commentcount) AS total_comments_on_posts,
        SUM(p.favoritecount) AS total_favorites
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    GROUP BY u.id, u.reputation
),
user_comments AS (
    SELECT
        u.id AS user_id,
        COUNT(c.id) AS comment_cnt
    FROM users u
    LEFT JOIN comments c ON c.userid = u.id
    GROUP BY u.id
),
user_votes_cast AS (
    SELECT
        u.id AS user_id,
        COUNT(v.id) AS votes_cast_cnt,
        SUM(v.bountyamount) AS bounty_amount_cast
    FROM users u
    LEFT JOIN votes v ON v.userid = u.id
    GROUP BY u.id
),
user_votes_received AS (
    SELECT
        u.id AS user_id,
        COUNT(v.id) AS votes_received_cnt,
        SUM(v.bountyamount) AS bounty_amount_received
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    LEFT JOIN votes v ON v.postid = p.id
    GROUP BY u.id
),
user_badges AS (
    SELECT
        u.id AS user_id,
        COUNT(b.id) AS badge_cnt
    FROM users u
    LEFT JOIN badges b ON b.userid = u.id
    GROUP BY u.id
),
user_edits AS (
    SELECT
        u.id AS user_id,
        COUNT(ph.id) AS edit_cnt
    FROM users u
    LEFT JOIN posthistory ph ON ph.userid = u.id
    GROUP BY u.id
),
user_tags AS (
    SELECT
        u.id AS user_id,
        COUNT(DISTINCT t.id) AS tag_cnt
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    LEFT JOIN tags t ON t.excerptpostid = p.id
    GROUP BY u.id
)
SELECT
    up.user_id,
    up.reputation,
    up.post_cnt,
    up.total_views,
    up.avg_post_score,
    up.total_answers,
    up.total_comments_on_posts,
    up.total_favorites,
    uc.comment_cnt,
    uv_cast.votes_cast_cnt,
    uv_cast.bounty_amount_cast,
    uv_recv.votes_received_cnt,
    uv_recv.bounty_amount_received,
    ub.badge_cnt,
    ue.edit_cnt,
    ut.tag_cnt,
    CASE WHEN up.post_cnt > 0 THEN CAST(uv_recv.votes_received_cnt AS double) / up.post_cnt ELSE NULL END AS avg_votes_received_per_post,
    CASE WHEN up.post_cnt > 0 THEN CAST(uc.comment_cnt AS double) / up.post_cnt ELSE NULL END AS avg_comments_written_per_post
FROM user_posts up
LEFT JOIN user_comments uc ON uc.user_id = up.user_id
LEFT JOIN user_votes_cast uv_cast ON uv_cast.user_id = up.user_id
LEFT JOIN user_votes_received uv_recv ON uv_recv.user_id = up.user_id
LEFT JOIN user_badges ub ON ub.user_id = up.user_id
LEFT JOIN user_edits ue ON ue.user_id = up.user_id
LEFT JOIN user_tags ut ON ut.user_id = up.user_id
ORDER BY up.reputation DESC
LIMIT 100
