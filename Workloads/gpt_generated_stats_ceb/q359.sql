WITH user_base AS (
    SELECT id, reputation, creationdate, views, upvotes, downvotes
    FROM users
),
user_posts AS (
    SELECT owneruserid AS user_id,
           COUNT(*) AS post_count,
           COALESCE(SUM(score), 0) AS total_post_score,
           COALESCE(AVG(score), 0) AS avg_post_score,
           COALESCE(SUM(viewcount), 0) AS total_post_views
    FROM posts
    GROUP BY owneruserid
),
user_comments AS (
    SELECT userid AS user_id,
           COUNT(*) AS comment_count
    FROM comments
    GROUP BY userid
),
user_votes AS (
    SELECT userid AS user_id,
           COUNT(*) AS vote_cast_count
    FROM votes
    GROUP BY userid
),
user_badges AS (
    SELECT userid AS user_id,
           COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
),
user_edits AS (
    SELECT lasteditoruserid AS user_id,
           COUNT(*) AS posts_edited_count
    FROM posts
    GROUP BY lasteditoruserid
)
SELECT
    ub.id AS user_id,
    ub.reputation,
    ub.creationdate,
    ub.views,
    ub.upvotes,
    ub.downvotes,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uv.vote_cast_count, 0) AS vote_cast_count,
    COALESCE(ubad.badge_count, 0) AS badge_count,
    COALESCE(up.total_post_score, 0) AS total_post_score,
    COALESCE(up.avg_post_score, 0) AS avg_post_score,
    COALESCE(up.total_post_views, 0) AS total_post_views,
    COALESCE(ue.posts_edited_count, 0) AS posts_edited_count
FROM user_base ub
LEFT JOIN user_posts up   ON up.user_id = ub.id
LEFT JOIN user_comments uc ON uc.user_id = ub.id
LEFT JOIN user_votes uv    ON uv.user_id = ub.id
LEFT JOIN user_badges ubad ON ubad.user_id = ub.id
LEFT JOIN user_edits ue    ON ue.user_id = ub.id
ORDER BY ub.reputation DESC
LIMIT 100
