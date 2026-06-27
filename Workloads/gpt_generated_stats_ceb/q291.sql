WITH user_posts AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS post_count,
        SUM(p.score) AS post_score_sum,
        SUM(p.viewcount) AS post_view_sum,
        AVG(p.viewcount) AS post_view_avg
    FROM posts p
    GROUP BY p.owneruserid
),
user_comments AS (
    SELECT
        c.userid AS user_id,
        COUNT(*) AS comment_count,
        SUM(c.score) AS comment_score_sum
    FROM comments c
    GROUP BY c.userid
),
user_post_edits AS (
    SELECT
        p.lasteditoruserid AS user_id,
        COUNT(*) AS edit_count
    FROM posts p
    WHERE p.lasteditoruserid IS NOT NULL
    GROUP BY p.lasteditoruserid
),
user_history AS (
    SELECT
        ph.userid AS user_id,
        COUNT(*) AS history_count
    FROM posthistory ph
    GROUP BY ph.userid
),
user_comments_on_own_posts AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS comments_on_own_posts
    FROM comments c
    JOIN posts p ON c.postid = p.id
    GROUP BY p.owneruserid
),
user_history_on_own_posts AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS history_on_own_posts
    FROM posthistory ph
    JOIN posts p ON ph.posthistorytypeid = p.id
    WHERE p.owneruserid IS NOT NULL
    GROUP BY p.owneruserid
)
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate AS user_creationdate,
    u.views AS user_views,
    u.upvotes,
    u.downvotes,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.post_score_sum, 0) AS post_score_sum,
    COALESCE(up.post_view_sum, 0) AS post_view_sum,
    COALESCE(up.post_view_avg, 0) AS post_view_avg,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uc.comment_score_sum, 0) AS comment_score_sum,
    COALESCE(ue.edit_count, 0) AS edit_count,
    COALESCE(uh.history_count, 0) AS history_count,
    COALESCE(uco.comments_on_own_posts, 0) AS comments_on_own_posts,
    COALESCE(uho.history_on_own_posts, 0) AS history_on_own_posts
FROM users u
LEFT JOIN user_posts up ON up.user_id = u.id
LEFT JOIN user_comments uc ON uc.user_id = u.id
LEFT JOIN user_post_edits ue ON ue.user_id = u.id
LEFT JOIN user_history uh ON uh.user_id = u.id
LEFT JOIN user_comments_on_own_posts uco ON uco.user_id = u.id
LEFT JOIN user_history_on_own_posts uho ON uho.user_id = u.id
ORDER BY u.reputation DESC
LIMIT 100
