WITH post_comment_stats AS (
    SELECT
        p.id AS post_id,
        p.posttypeid,
        p.owneruserid,
        p.creationdate AS post_creationdate,
        COUNT(c.id) AS comment_count,
        SUM(c.score) AS total_comment_score,
        AVG(c.score) AS avg_comment_score,
        MAX(c.creationdate) AS latest_comment_date,
        MIN(c.creationdate) AS earliest_comment_date
    FROM posts p
    LEFT JOIN comments c
        ON c.postid = p.id
    GROUP BY p.id, p.posttypeid, p.owneruserid, p.creationdate
)
SELECT
    post_id,
    posttypeid,
    owneruserid,
    comment_count,
    total_comment_score,
    avg_comment_score,
    date_diff('day', earliest_comment_date, latest_comment_date) AS comment_span_days
FROM post_comment_stats
WHERE comment_count > 0
ORDER BY total_comment_score DESC
LIMIT 20
