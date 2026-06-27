WITH user_posts AS (
    SELECT
        p.owneruserid AS userid,
        COUNT(*) AS post_count,
        AVG(p.score) AS avg_post_score,
        SUM(p.viewcount) AS total_viewcount,
        SUM(p.favoritecount) AS total_favoritecount
    FROM posts p
    GROUP BY p.owneruserid
),
user_comments_written AS (
    SELECT
        c.userid AS userid,
        COUNT(*) AS comment_written_count
    FROM comments c
    GROUP BY c.userid
),
user_comments_received AS (
    SELECT
        p.owneruserid AS userid,
        COUNT(*) AS comment_received_count
    FROM posts p
    JOIN comments c ON c.postid = p.id
    GROUP BY p.owneruserid
),
user_votes_cast AS (
    SELECT
        v.userid AS userid,
        COUNT(*) AS votes_cast_count
    FROM votes v
    GROUP BY v.userid
),
user_votes_received AS (
    SELECT
        p.owneruserid AS userid,
        COUNT(*) AS votes_received_count
    FROM posts p
    JOIN votes v ON v.postid = p.id
    GROUP BY p.owneruserid
),
user_badges AS (
    SELECT
        b.userid AS userid,
        COUNT(*) AS badge_count
    FROM badges b
    GROUP BY b.userid
),
user_posthistory AS (
    SELECT
        ph.userid AS userid,
        COUNT(*) AS posthistory_count
    FROM posthistory ph
    GROUP BY ph.userid
),
user_tags_excerpt AS (
    SELECT
        p.owneruserid AS userid,
        COUNT(*) AS tags_excerpt_count
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
)
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    u.views,
    u.upvotes,
    u.downvotes,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.avg_post_score, 0) AS avg_post_score,
    COALESCE(up.total_viewcount, 0) AS total_viewcount,
    COALESCE(up.total_favoritecount, 0) AS total_favoritecount,
    COALESCE(ucw.comment_written_count, 0) AS comment_written_count,
    COALESCE(ucr.comment_received_count, 0) AS comment_received_count,
    COALESCE(uvc.votes_cast_count, 0) AS votes_cast_count,
    COALESCE(uvr.votes_received_count, 0) AS votes_received_count,
    COALESCE(ub.badge_count, 0) AS badge_count,
    COALESCE(uph.posthistory_count, 0) AS posthistory_count,
    COALESCE(ut.tags_excerpt_count, 0) AS tags_excerpt_count
FROM users u
LEFT JOIN user_posts up ON up.userid = u.id
LEFT JOIN user_comments_written ucw ON ucw.userid = u.id
LEFT JOIN user_comments_received ucr ON ucr.userid = u.id
LEFT JOIN user_votes_cast uvc ON uvc.userid = u.id
LEFT JOIN user_votes_received uvr ON uvr.userid = u.id
LEFT JOIN user_badges ub ON ub.userid = u.id
LEFT JOIN user_posthistory uph ON uph.userid = u.id
LEFT JOIN user_tags_excerpt ut ON ut.userid = u.id
ORDER BY u.reputation DESC, post_count DESC
LIMIT 20
