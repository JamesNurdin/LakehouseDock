WITH tag_totals AS (
    SELECT
        excerptpostid,
        SUM(count) AS total_tag_count
    FROM tags
    GROUP BY excerptpostid
)
SELECT
    p.posttypeid,
    FLOOR(p.score / 10) AS score_bucket,
    COUNT(*) AS post_cnt,
    SUM(p.score) AS total_score,
    AVG(p.score) AS avg_score,
    SUM(p.viewcount) AS total_views,
    AVG(p.answercount) AS avg_answers,
    SUM(COALESCE(t.total_tag_count, 0)) AS total_tag_count
FROM posts p
LEFT JOIN tag_totals t
    ON t.excerptpostid = p.id
WHERE p.posttypeid IN (1, 2)
GROUP BY p.posttypeid, FLOOR(p.score / 10)
ORDER BY p.posttypeid, FLOOR(p.score / 10)
