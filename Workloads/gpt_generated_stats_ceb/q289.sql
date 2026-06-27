WITH user_posts AS (
    SELECT
        u.id AS user_id,
        u.reputation,
        SUM(p.score) AS total_post_score,
        COUNT(p.id) AS post_count,
        AVG(p.score) AS avg_post_score,
        SUM(p.viewcount) AS total_viewcount
    FROM users u
    JOIN posts p ON p.owneruserid = u.id
    GROUP BY u.id, u.reputation
),
user_comments AS (
    SELECT
        u.id AS user_id,
        COUNT(c.id) AS comment_count,
        AVG(c.score) AS avg_comment_score
    FROM users u
    JOIN comments c ON c.userid = u.id
    GROUP BY u.id
),
user_votes_on_posts AS (
    SELECT
        u.id AS user_id,
        COUNT(v.id) AS vote_on_posts_count,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvote_count,
        SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvote_count
    FROM users u
    JOIN posts p ON p.owneruserid = u.id
    JOIN votes v ON v.postid = p.id
    GROUP BY u.id
),
user_badges AS (
    SELECT
        u.id AS user_id,
        COUNT(b.id) AS badge_count
    FROM users u
    JOIN badges b ON b.userid = u.id
    GROUP BY u.id
),
user_tags AS (
    SELECT
        u.id AS user_id,
        COUNT(DISTINCT t.id) AS distinct_tag_count
    FROM users u
    JOIN posts p ON p.owneruserid = u.id
    JOIN tags t ON t.excerptpostid = p.id
    GROUP BY u.id
),
user_edit_history AS (
    SELECT
        u.id AS user_id,
        COUNT(ph.id) AS edit_count
    FROM users u
    JOIN posthistory ph ON ph.userid = u.id
    LEFT JOIN posts p ON ph.posthistorytypeid = p.id
    GROUP BY u.id
),
user_postlinks AS (
    SELECT
        u.id AS user_id,
        COUNT(pl.id) AS link_count
    FROM users u
    JOIN posts p ON p.owneruserid = u.id
    JOIN postlinks pl ON pl.postid = p.id
    GROUP BY u.id
)
SELECT
    up.user_id,
    up.reputation,
    up.total_post_score,
    up.post_count,
    up.avg_post_score,
    up.total_viewcount,
    uc.comment_count,
    uc.avg_comment_score,
    uv.vote_on_posts_count,
    uv.upvote_count,
    uv.downvote_count,
    ub.badge_count,
    ut.distinct_tag_count,
    ue.edit_count,
    upl.link_count
FROM user_posts up
LEFT JOIN user_comments uc ON uc.user_id = up.user_id
LEFT JOIN user_votes_on_posts uv ON uv.user_id = up.user_id
LEFT JOIN user_badges ub ON ub.user_id = up.user_id
LEFT JOIN user_tags ut ON ut.user_id = up.user_id
LEFT JOIN user_edit_history ue ON ue.user_id = up.user_id
LEFT JOIN user_postlinks upl ON upl.user_id = up.user_id
ORDER BY up.total_post_score DESC
LIMIT 10
