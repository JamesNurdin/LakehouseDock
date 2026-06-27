WITH user_posts AS (
    SELECT
        u.id AS user_id,
        u.reputation,
        COUNT(p.id) AS total_posts,
        COALESCE(SUM(p.answercount), 0) AS total_answers,
        COALESCE(SUM(p.viewcount), 0) AS total_post_views,
        COALESCE(AVG(p.score), 0) AS avg_post_score,
        COALESCE(SUM(p.favoritecount), 0) AS total_favorite_count
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    GROUP BY u.id, u.reputation
),
user_comments_written AS (
    SELECT
        u.id AS user_id,
        COUNT(c.id) AS comments_written
    FROM users u
    LEFT JOIN comments c ON c.userid = u.id
    GROUP BY u.id
),
user_comments_received AS (
    SELECT
        u.id AS user_id,
        COUNT(c.id) AS comments_received
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    LEFT JOIN comments c ON c.postid = p.id
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
user_badges AS (
    SELECT
        u.id AS user_id,
        COUNT(b.id) AS badge_count
    FROM users u
    LEFT JOIN badges b ON b.userid = u.id
    GROUP BY u.id
),
user_tags_used AS (
    SELECT
        u.id AS user_id,
        COUNT(DISTINCT t.id) AS tags_used
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    LEFT JOIN tags t ON t.excerptpostid = p.id
    GROUP BY u.id
),
user_posthistory_events AS (
    SELECT
        u.id AS user_id,
        COUNT(ph.id) AS posthistory_events
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    LEFT JOIN posthistory ph ON ph.posthistorytypeid = p.id
    GROUP BY u.id
),
user_posts_edited AS (
    SELECT
        u.id AS user_id,
        COUNT(p.id) AS posts_edited
    FROM users u
    LEFT JOIN posts p ON p.lasteditoruserid = u.id
    GROUP BY u.id
)
SELECT
    up.user_id,
    up.reputation,
    up.total_posts,
    up.total_answers,
    up.total_post_views,
    up.avg_post_score,
    up.total_favorite_count,
    ucw.comments_written,
    ucr.comments_received,
    uv_cast.votes_cast,
    uv_recv.votes_received,
    ub.badge_count,
    ut.tags_used,
    uph.posthistory_events,
    upe.posts_edited
FROM user_posts up
LEFT JOIN user_comments_written ucw ON ucw.user_id = up.user_id
LEFT JOIN user_comments_received ucr ON ucr.user_id = up.user_id
LEFT JOIN user_votes_cast uv_cast ON uv_cast.user_id = up.user_id
LEFT JOIN user_votes_received uv_recv ON uv_recv.user_id = up.user_id
LEFT JOIN user_badges ub ON ub.user_id = up.user_id
LEFT JOIN user_tags_used ut ON ut.user_id = up.user_id
LEFT JOIN user_posthistory_events uph ON uph.user_id = up.user_id
LEFT JOIN user_posts_edited upe ON upe.user_id = up.user_id
ORDER BY up.total_posts DESC
LIMIT 100
