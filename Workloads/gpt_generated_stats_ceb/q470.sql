WITH post_owned AS (
    SELECT owneruserid AS user_id,
           COUNT(*) AS posts_owned,
           COALESCE(SUM(score), 0) AS total_score_owned
    FROM posts
    GROUP BY owneruserid
),
post_edited AS (
    SELECT lasteditoruserid AS user_id,
           COUNT(*) AS posts_edited
    FROM posts
    GROUP BY lasteditoruserid
),
user_comments AS (
    SELECT userid AS user_id,
           COUNT(*) AS comments_made
    FROM comments
    GROUP BY userid
),
user_votes_cast AS (
    SELECT userid AS user_id,
           COUNT(*) AS votes_cast
    FROM votes
    GROUP BY userid
),
votes_received AS (
    SELECT p.owneruserid AS user_id,
           COUNT(*) AS votes_received
    FROM votes v
    JOIN posts p ON v.postid = p.id
    GROUP BY p.owneruserid
),
user_badges AS (
    SELECT userid AS user_id,
           COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
),
user_posthistory AS (
    SELECT userid AS user_id,
           COUNT(*) AS history_events
    FROM posthistory
    GROUP BY userid
),
user_tags AS (
    SELECT p.owneruserid AS user_id,
           COUNT(DISTINCT t.id) AS tags_on_owned_posts
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
)
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(po.posts_owned, 0) AS posts_owned,
    COALESCE(po.total_score_owned, 0) AS total_score_owned,
    COALESCE(pe.posts_edited, 0) AS posts_edited,
    COALESCE(uc.comments_made, 0) AS comments_made,
    COALESCE(uvc.votes_cast, 0) AS votes_cast,
    COALESCE(vr.votes_received, 0) AS votes_received,
    COALESCE(ub.badge_count, 0) AS badge_count,
    COALESCE(up.history_events, 0) AS post_history_events,
    COALESCE(ut.tags_on_owned_posts, 0) AS tags_on_owned_posts
FROM users u
LEFT JOIN post_owned po ON po.user_id = u.id
LEFT JOIN post_edited pe ON pe.user_id = u.id
LEFT JOIN user_comments uc ON uc.user_id = u.id
LEFT JOIN user_votes_cast uvc ON uvc.user_id = u.id
LEFT JOIN votes_received vr ON vr.user_id = u.id
LEFT JOIN user_badges ub ON ub.user_id = u.id
LEFT JOIN user_posthistory up ON up.user_id = u.id
LEFT JOIN user_tags ut ON ut.user_id = u.id
ORDER BY u.reputation DESC
LIMIT 100
