WITH user_badges AS (
    SELECT
        users.id AS user_id,
        COUNT(badges.id) AS badge_count
    FROM users
    LEFT JOIN badges ON badges.userid = users.id
    GROUP BY users.id
),
user_posts AS (
    SELECT
        users.id AS user_id,
        COUNT(posts.id) AS post_count,
        SUM(posts.score) AS total_post_score,
        AVG(posts.score) AS avg_post_score
    FROM users
    LEFT JOIN posts ON posts.owneruserid = users.id
    GROUP BY users.id
),
user_comments AS (
    SELECT
        users.id AS user_id,
        COUNT(comments.id) AS comment_count
    FROM users
    LEFT JOIN comments ON comments.userid = users.id
    GROUP BY users.id
),
user_votes AS (
    SELECT
        users.id AS user_id,
        COUNT(votes.id) AS vote_count
    FROM users
    LEFT JOIN votes ON votes.userid = users.id
    GROUP BY users.id
),
user_edits AS (
    SELECT
        users.id AS user_id,
        COUNT(posts.id) AS edited_post_count
    FROM users
    LEFT JOIN posts ON posts.lasteditoruserid = users.id
    GROUP BY users.id
),
user_posthistory AS (
    SELECT
        users.id AS user_id,
        COUNT(posthistory.id) AS posthistory_count
    FROM users
    LEFT JOIN posthistory ON posthistory.userid = users.id
    GROUP BY users.id
),
user_tags AS (
    SELECT
        users.id AS user_id,
        COUNT(DISTINCT tags.id) AS tag_count
    FROM users
    LEFT JOIN posts ON posts.owneruserid = users.id
    LEFT JOIN tags ON tags.excerptpostid = posts.id
    GROUP BY users.id
)
SELECT
    u.id,
    u.reputation,
    COALESCE(ub.badge_count, 0) AS badge_count,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.total_post_score, 0) AS total_post_score,
    COALESCE(up.avg_post_score, 0) AS avg_post_score,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uv.vote_count, 0) AS vote_count,
    COALESCE(ue.edited_post_count, 0) AS edited_post_count,
    COALESCE(uph.posthistory_count, 0) AS posthistory_count,
    COALESCE(ut.tag_count, 0) AS tag_count
FROM users u
LEFT JOIN user_badges ub ON ub.user_id = u.id
LEFT JOIN user_posts up ON up.user_id = u.id
LEFT JOIN user_comments uc ON uc.user_id = u.id
LEFT JOIN user_votes uv ON uv.user_id = u.id
LEFT JOIN user_edits ue ON ue.user_id = u.id
LEFT JOIN user_posthistory uph ON uph.user_id = u.id
LEFT JOIN user_tags ut ON ut.user_id = u.id
ORDER BY badge_count DESC, total_post_score DESC
LIMIT 100
