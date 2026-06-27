WITH user_posts AS (
    SELECT
        owneruserid AS user_id,
        COUNT(*) AS post_count,
        SUM(score) AS total_score
    FROM posts
    GROUP BY owneruserid
),
user_comments AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS comment_count
    FROM comments
    GROUP BY userid
),
user_badges AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
),
user_votes_cast AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS votes_cast
    FROM votes
    GROUP BY userid
),
user_votes_received AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS votes_received
    FROM votes v
    JOIN posts p ON v.postid = p.id
    GROUP BY p.owneruserid
),
user_edits AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS edit_count
    FROM posthistory
    GROUP BY userid
),
user_last_edits AS (
    SELECT
        lasteditoruserid AS user_id,
        COUNT(*) AS last_edit_count
    FROM posts
    WHERE lasteditoruserid IS NOT NULL
    GROUP BY lasteditoruserid
),
tag_excerpt_posts AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS tag_excerpt_post_count
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
)
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(up.post_count, 0) AS total_posts,
    COALESCE(up.total_score, 0) AS total_post_score,
    COALESCE(uc.comment_count, 0) AS total_comments,
    COALESCE(ub.badge_count, 0) AS total_badges,
    COALESCE(uvc.votes_cast, 0) AS total_votes_cast,
    COALESCE(uvr.votes_received, 0) AS total_votes_received,
    COALESCE(ue.edit_count, 0) AS total_edits,
    COALESCE(ule.last_edit_count, 0) AS total_last_edits,
    COALESCE(tp.tag_excerpt_post_count, 0) AS tag_excerpt_posts
FROM users u
LEFT JOIN user_posts up ON up.user_id = u.id
LEFT JOIN user_comments uc ON uc.user_id = u.id
LEFT JOIN user_badges ub ON ub.user_id = u.id
LEFT JOIN user_votes_cast uvc ON uvc.user_id = u.id
LEFT JOIN user_votes_received uvr ON uvr.user_id = u.id
LEFT JOIN user_edits ue ON ue.user_id = u.id
LEFT JOIN user_last_edits ule ON ule.user_id = u.id
LEFT JOIN tag_excerpt_posts tp ON tp.user_id = u.id
ORDER BY total_posts DESC, u.reputation DESC
LIMIT 100
