WITH comment_delays AS (
    SELECT
        p.posttypeid,
        date_diff('second', p.creationdate, c.creationdate) AS delay_seconds,
        c.score AS comment_score,
        p.id AS post_id
    FROM posts p
    JOIN comments c
        ON c.postid = p.id
)
SELECT
    posttypeid,
    COUNT(*) AS total_comments,
    AVG(delay_seconds) AS avg_delay_seconds,
    AVG(comment_score) AS avg_comment_score,
    approx_percentile(delay_seconds, 0.5) AS median_delay_seconds,
    MAX(delay_seconds) AS max_delay_seconds
FROM comment_delays
GROUP BY posttypeid
ORDER BY avg_delay_seconds DESC
