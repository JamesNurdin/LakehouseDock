WITH user_activity AS (
    SELECT
        u.id AS user_id,
        u.reputation,
        u.creationdate AS user_creationdate,
        u.views AS user_views,
        u.upvotes AS user_upvotes,
        u.downvotes AS user_downvotes,
        COUNT(DISTINCT p.id) AS post_count,
        COALESCE(SUM(p.score), 0) AS total_post_score,
        COALESCE(SUM(p.viewcount), 0) AS total_post_views,
        COUNT(DISTINCT c.id) AS comment_count,
        COUNT(DISTINCT v.id) AS vote_cast_count,
        COUNT(DISTINCT vb.id) AS vote_received_count,
        COUNT(DISTINCT b.id) AS badge_count,
        COUNT(DISTINCT ph.id) AS post_history_count,
        COUNT(DISTINCT t.id) AS tag_excerpt_count
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    LEFT JOIN comments c ON c.userid = u.id
    LEFT JOIN votes v ON v.userid = u.id
    LEFT JOIN votes vb ON vb.postid = p.id
    LEFT JOIN badges b ON b.userid = u.id
    LEFT JOIN posthistory ph ON ph.userid = u.id
    LEFT JOIN tags t ON t.excerptpostid = p.id
    GROUP BY u.id, u.reputation, u.creationdate, u.views, u.upvotes, u.downvotes
)
SELECT
    ROW_NUMBER() OVER (ORDER BY post_count DESC) AS user_rank,
    user_id,
    reputation,
    user_creationdate,
    user_views,
    user_upvotes,
    user_downvotes,
    post_count,
    total_post_score,
    total_post_views,
    comment_count,
    vote_cast_count,
    vote_received_count,
    badge_count,
    post_history_count,
    tag_excerpt_count
FROM user_activity
ORDER BY post_count DESC
LIMIT 10
