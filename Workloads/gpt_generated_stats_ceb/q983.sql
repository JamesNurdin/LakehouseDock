WITH user_stats AS (
    SELECT
        u.id AS user_id,
        u.reputation,
        u.creationdate AS user_creationdate,
        u.views AS user_views,
        u.upvotes,
        u.downvotes,
        COUNT(DISTINCT p.id) AS post_count,
        SUM(COALESCE(p.score, 0)) AS total_post_score,
        SUM(COALESCE(p.viewcount, 0)) AS total_post_views,
        COUNT(DISTINCT c.id) AS comment_count,
        SUM(COALESCE(c.score, 0)) AS total_comment_score,
        COUNT(DISTINCT v.id) AS vote_given_count,
        SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_given_count,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_given_count,
        COUNT(DISTINCT b.id) AS badge_count,
        COUNT(DISTINCT t.id) AS tag_excerpt_post_count
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    LEFT JOIN comments c ON c.userid = u.id
    LEFT JOIN votes v ON v.userid = u.id
    LEFT JOIN badges b ON b.userid = u.id
    LEFT JOIN tags t ON t.excerptpostid = p.id
    GROUP BY u.id, u.reputation, u.creationdate, u.views, u.upvotes, u.downvotes
)
SELECT
    user_id,
    reputation,
    user_creationdate,
    user_views,
    upvotes,
    downvotes,
    post_count,
    total_post_score,
    total_post_views,
    comment_count,
    total_comment_score,
    vote_given_count,
    upvote_given_count,
    downvote_given_count,
    badge_count,
    tag_excerpt_post_count,
    CAST(total_post_score AS DOUBLE) / NULLIF(post_count, 0) AS avg_post_score,
    CAST(total_comment_score AS DOUBLE) / NULLIF(comment_count, 0) AS avg_comment_score
FROM user_stats
ORDER BY reputation DESC
LIMIT 100
