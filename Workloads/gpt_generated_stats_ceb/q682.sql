WITH user_stats AS (
    SELECT
        u.id AS user_id,
        u.reputation,
        u.creationdate,
        u.views,
        u.upvotes,
        u.downvotes,
        COALESCE(p.total_posts, 0) AS total_posts,
        COALESCE(p.total_post_score, 0) AS total_post_score,
        COALESCE(p.total_post_views, 0) AS total_post_views,
        COALESCE(c.total_comments, 0) AS total_comments,
        COALESCE(c.total_comment_score, 0) AS total_comment_score,
        COALESCE(v_cast.total_votes_cast, 0) AS total_votes_cast,
        COALESCE(v_recv.total_votes_received, 0) AS total_votes_received,
        COALESCE(b.total_badges, 0) AS total_badges,
        COALESCE(e.total_edits, 0) AS total_edits
    FROM users u
    LEFT JOIN (
        SELECT
            owneruserid AS user_id,
            COUNT(*) AS total_posts,
            SUM(score) AS total_post_score,
            SUM(viewcount) AS total_post_views
        FROM posts
        GROUP BY owneruserid
    ) p ON p.user_id = u.id
    LEFT JOIN (
        SELECT
            userid AS user_id,
            COUNT(*) AS total_comments,
            SUM(score) AS total_comment_score
        FROM comments
        GROUP BY userid
    ) c ON c.user_id = u.id
    LEFT JOIN (
        SELECT
            userid AS user_id,
            COUNT(*) AS total_votes_cast
        FROM votes
        GROUP BY userid
    ) v_cast ON v_cast.user_id = u.id
    LEFT JOIN (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS total_votes_received
        FROM votes v
        JOIN posts p ON v.postid = p.id
        GROUP BY p.owneruserid
    ) v_recv ON v_recv.user_id = u.id
    LEFT JOIN (
        SELECT
            userid AS user_id,
            COUNT(*) AS total_badges
        FROM badges
        GROUP BY userid
    ) b ON b.user_id = u.id
    LEFT JOIN (
        SELECT
            lasteditoruserid AS user_id,
            COUNT(*) AS total_edits
        FROM posts
        GROUP BY lasteditoruserid
    ) e ON e.user_id = u.id
)
SELECT
    user_id,
    reputation,
    total_posts,
    total_post_score,
    total_post_views,
    total_comments,
    total_comment_score,
    total_votes_cast,
    total_votes_received,
    total_badges,
    total_edits,
    CASE WHEN total_posts > 0 THEN total_post_score / total_posts END AS avg_post_score,
    CASE WHEN total_comments > 0 THEN total_comment_score / total_comments END AS avg_comment_score
FROM user_stats
ORDER BY reputation DESC
LIMIT 20
