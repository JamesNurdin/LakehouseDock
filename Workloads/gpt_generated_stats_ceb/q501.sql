WITH post_comment_stats AS (
    SELECT
        p.posttypeid,
        COUNT(DISTINCT p.id) AS post_count,
        SUM(p.score) AS total_post_score,
        AVG(p.score) AS avg_post_score,
        SUM(p.viewcount) AS total_viewcount,
        AVG(p.viewcount) AS avg_viewcount,
        SUM(p.answercount) AS total_answercount,
        AVG(p.answercount) AS avg_answercount,
        COUNT(c.id) AS comment_count,
        SUM(c.score) AS total_comment_score,
        AVG(c.score) AS avg_comment_score
    FROM posts p
    LEFT JOIN comments c ON c.postid = p.id
    GROUP BY p.posttypeid
    HAVING COUNT(DISTINCT p.id) >= 10
)
SELECT
    posttypeid,
    post_count,
    total_post_score,
    avg_post_score,
    total_viewcount,
    avg_viewcount,
    total_answercount,
    avg_answercount,
    comment_count,
    total_comment_score,
    avg_comment_score
FROM post_comment_stats
ORDER BY posttypeid
