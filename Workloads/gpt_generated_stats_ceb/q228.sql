WITH user_posts AS (
    SELECT
        owneruserid AS user_id,
        COUNT(*) AS post_count,
        COALESCE(SUM(score), 0) AS total_post_score,
        COALESCE(SUM(viewcount), 0) AS total_view_count,
        COALESCE(SUM(answercount), 0) AS total_answer_count,
        COALESCE(SUM(commentcount), 0) AS total_comment_count,
        COALESCE(SUM(favoritecount), 0) AS total_favorite_count,
        MIN(creationdate) AS first_post_date,
        MAX(creationdate) AS last_post_date
    FROM posts
    GROUP BY owneruserid
),
user_comments AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS comment_made_count,
        COALESCE(SUM(score), 0) AS total_comment_score
    FROM comments
    GROUP BY userid
),
user_votes AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS vote_cast_count
    FROM votes
    GROUP BY userid
),
user_badges AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
),
user_posthistory AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS posthistory_count
    FROM posthistory
    GROUP BY userid
),
user_tags AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(DISTINCT t.id) AS tag_excerpt_count
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
),
user_base AS (
    SELECT
        u.id AS user_id,
        u.reputation
    FROM users u
)
SELECT
    ub.user_id,
    ub.reputation,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.total_post_score, 0) AS total_post_score,
    COALESCE(up.total_view_count, 0) AS total_view_count,
    COALESCE(up.total_answer_count, 0) AS total_answer_count,
    COALESCE(up.total_comment_count, 0) AS total_comment_count,
    COALESCE(up.total_favorite_count, 0) AS total_favorite_count,
    COALESCE(uc.comment_made_count, 0) AS comment_made_count,
    COALESCE(uc.total_comment_score, 0) AS total_comment_score,
    COALESCE(uv.vote_cast_count, 0) AS vote_cast_count,
    COALESCE(ubd.badge_count, 0) AS badge_count,
    COALESCE(uph.posthistory_count, 0) AS posthistory_count,
    COALESCE(ut.tag_excerpt_count, 0) AS tag_excerpt_count,
    up.first_post_date,
    up.last_post_date,
    (COALESCE(up.post_count, 0) + COALESCE(uc.comment_made_count, 0) + COALESCE(uv.vote_cast_count, 0) + COALESCE(ubd.badge_count, 0)) AS total_activity_score
FROM user_base ub
LEFT JOIN user_posts up ON up.user_id = ub.user_id
LEFT JOIN user_comments uc ON uc.user_id = ub.user_id
LEFT JOIN user_votes uv ON uv.user_id = ub.user_id
LEFT JOIN user_badges ubd ON ubd.user_id = ub.user_id
LEFT JOIN user_posthistory uph ON uph.user_id = ub.user_id
LEFT JOIN user_tags ut ON ut.user_id = ub.user_id
ORDER BY total_activity_score DESC
LIMIT 100
