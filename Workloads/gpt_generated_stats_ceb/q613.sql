WITH
    user_info AS (
        SELECT
            id,
            reputation,
            creationdate,
            views,
            upvotes,
            downvotes
        FROM users
    ),
    post_owner_agg AS (
        SELECT
            owneruserid AS user_id,
            COUNT(*) AS posts_authored,
            SUM(score) AS total_post_score,
            SUM(viewcount) AS total_post_views,
            AVG(score) AS avg_post_score,
            SUM(answercount) AS total_answer_count,
            SUM(commentcount) AS total_comment_count,
            SUM(favoritecount) AS total_favorite_count
        FROM posts
        GROUP BY owneruserid
    ),
    post_editor_agg AS (
        SELECT
            lasteditoruserid AS user_id,
            COUNT(*) AS posts_edited,
            SUM(score) AS total_edited_post_score,
            AVG(score) AS avg_edited_post_score
        FROM posts
        GROUP BY lasteditoruserid
    ),
    comment_agg AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS comments_made,
            SUM(score) AS total_comment_score,
            AVG(score) AS avg_comment_score
        FROM comments
        GROUP BY userid
    ),
    badge_agg AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS badge_count
        FROM badges
        GROUP BY userid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    year(u.creationdate) AS creation_year,
    u.views AS user_views,
    u.upvotes,
    u.downvotes,
    COALESCE(p.posts_authored, 0) AS posts_authored,
    COALESCE(p.total_post_score, 0) AS total_post_score,
    COALESCE(p.total_post_views, 0) AS total_post_views,
    COALESCE(p.avg_post_score, 0) AS avg_post_score,
    COALESCE(e.posts_edited, 0) AS posts_edited,
    COALESCE(e.total_edited_post_score, 0) AS total_edited_post_score,
    COALESCE(e.avg_edited_post_score, 0) AS avg_edited_post_score,
    COALESCE(c.comments_made, 0) AS comments_made,
    COALESCE(c.total_comment_score, 0) AS total_comment_score,
    COALESCE(c.avg_comment_score, 0) AS avg_comment_score,
    COALESCE(b.badge_count, 0) AS badge_count
FROM user_info u
LEFT JOIN post_owner_agg p ON p.user_id = u.id
LEFT JOIN post_editor_agg e ON e.user_id = u.id
LEFT JOIN comment_agg c ON c.user_id = u.id
LEFT JOIN badge_agg b ON b.user_id = u.id
ORDER BY u.reputation DESC
LIMIT 50
