WITH user_posts AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS post_count,
        COALESCE(SUM(p.score), 0) AS total_post_score,
        COALESCE(AVG(p.score), 0) AS avg_post_score,
        COALESCE(SUM(p.viewcount), 0) AS total_view_count
    FROM posts p
    GROUP BY p.owneruserid
),
user_comments_made AS (
    SELECT
        c.userid AS user_id,
        COUNT(*) AS comment_made_count,
        COALESCE(SUM(c.score), 0) AS comment_made_score
    FROM comments c
    GROUP BY c.userid
),
user_comments_received AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS comment_received_count
    FROM posts p
    JOIN comments c ON c.postid = p.id
    GROUP BY p.owneruserid
),
user_votes_cast AS (
    SELECT
        v.userid AS user_id,
        COUNT(*) AS vote_cast_count
    FROM votes v
    GROUP BY v.userid
),
user_votes_received AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS vote_received_count
    FROM posts p
    JOIN votes v ON v.postid = p.id
    GROUP BY p.owneruserid
),
user_badges AS (
    SELECT
        b.userid AS user_id,
        COUNT(*) AS badge_count
    FROM badges b
    GROUP BY b.userid
),
user_tags AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(DISTINCT t.id) AS tag_count
    FROM posts p
    JOIN tags t ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
),
user_posthistory AS (
    SELECT
        ph.userid AS user_id,
        COUNT(*) AS posthistory_event_count
    FROM posthistory ph
    GROUP BY ph.userid
)
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.total_post_score, 0) AS total_post_score,
    COALESCE(up.avg_post_score, 0) AS avg_post_score,
    COALESCE(up.total_view_count, 0) AS total_view_count,
    COALESCE(ucm.comment_made_count, 0) AS comment_made_count,
    COALESCE(ucm.comment_made_score, 0) AS comment_made_score,
    COALESCE(ucr.comment_received_count, 0) AS comment_received_count,
    COALESCE(uvc.vote_cast_count, 0) AS vote_cast_count,
    COALESCE(uvr.vote_received_count, 0) AS vote_received_count,
    COALESCE(ub.badge_count, 0) AS badge_count,
    COALESCE(ut.tag_count, 0) AS tag_count,
    COALESCE(uph.posthistory_event_count, 0) AS posthistory_event_count
FROM users u
LEFT JOIN user_posts up ON up.user_id = u.id
LEFT JOIN user_comments_made ucm ON ucm.user_id = u.id
LEFT JOIN user_comments_received ucr ON ucr.user_id = u.id
LEFT JOIN user_votes_cast uvc ON uvc.user_id = u.id
LEFT JOIN user_votes_received uvr ON uvr.user_id = u.id
LEFT JOIN user_badges ub ON ub.user_id = u.id
LEFT JOIN user_tags ut ON ut.user_id = u.id
LEFT JOIN user_posthistory uph ON uph.user_id = u.id
ORDER BY total_post_score DESC
LIMIT 100
