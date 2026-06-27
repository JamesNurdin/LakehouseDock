WITH user_info AS (
    SELECT id, reputation
    FROM users
),
user_posts AS (
    SELECT owneruserid AS user_id,
           COUNT(*) AS post_count,
           SUM(score) AS total_post_score,
           AVG(score) AS avg_post_score
    FROM posts
    GROUP BY owneruserid
),
user_comments AS (
    SELECT userid AS user_id,
           COUNT(*) AS comment_count,
           SUM(score) AS total_comment_score,
           AVG(score) AS avg_comment_score
    FROM comments
    GROUP BY userid
),
user_votes_cast AS (
    SELECT userid AS user_id,
           COUNT(*) AS votes_cast
    FROM votes
    GROUP BY userid
),
user_votes_received AS (
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
user_edits AS (
    SELECT userid AS user_id,
           COUNT(*) AS edit_count
    FROM posthistory
    GROUP BY userid
),
user_tags AS (
    SELECT p.owneruserid AS user_id,
           COUNT(DISTINCT t.id) AS tag_count
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
)
SELECT
    ui.id AS user_id,
    ui.reputation,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.total_post_score, 0) AS total_post_score,
    COALESCE(up.avg_post_score, 0) AS avg_post_score,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uc.total_comment_score, 0) AS total_comment_score,
    COALESCE(uc.avg_comment_score, 0) AS avg_comment_score,
    COALESCE(uvc.votes_cast, 0) AS votes_cast,
    COALESCE(uvr.votes_received, 0) AS votes_received,
    COALESCE(ub.badge_count, 0) AS badge_count,
    COALESCE(ue.edit_count, 0) AS edit_count,
    COALESCE(ut.tag_count, 0) AS tag_count
FROM user_info ui
LEFT JOIN user_posts up ON ui.id = up.user_id
LEFT JOIN user_comments uc ON ui.id = uc.user_id
LEFT JOIN user_votes_cast uvc ON ui.id = uvc.user_id
LEFT JOIN user_votes_received uvr ON ui.id = uvr.user_id
LEFT JOIN user_badges ub ON ui.id = ub.user_id
LEFT JOIN user_edits ue ON ui.id = ue.user_id
LEFT JOIN user_tags ut ON ui.id = ut.user_id
ORDER BY post_count DESC, total_post_score DESC
LIMIT 100
