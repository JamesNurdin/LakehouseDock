WITH user_comment_stats AS (
    SELECT
        comments.userid AS user_id,
        count(*) AS comment_count,
        sum(comments.score) AS total_score,
        avg(comments.score) AS avg_score,
        min(comments.creationdate) AS first_comment_date,
        max(comments.creationdate) AS last_comment_date
    FROM comments
    WHERE comments.creationdate >= current_timestamp - interval '1' year
    GROUP BY comments.userid
    HAVING count(*) >= 10
)
SELECT
    u.id,
    u.reputation,
    u.creationdate AS user_creationdate,
    u.views,
    u.upvotes,
    u.downvotes,
    ucs.comment_count,
    ucs.total_score,
    ucs.avg_score,
    ucs.first_comment_date,
    ucs.last_comment_date,
    rank() OVER (ORDER BY ucs.avg_score DESC) AS user_rank
FROM user_comment_stats ucs
JOIN users u
    ON ucs.user_id = u.id
WHERE u.reputation >= 1000
ORDER BY user_rank
LIMIT 100
