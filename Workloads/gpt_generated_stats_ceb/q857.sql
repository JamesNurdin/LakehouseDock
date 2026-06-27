WITH post_hist_counts AS (
    SELECT
        posthistorytypeid AS post_id,
        COUNT(*) AS hist_count,
        COUNT(DISTINCT userid) AS distinct_user_hist
    FROM posthistory
    GROUP BY posthistorytypeid
)
SELECT
    p.posttypeid,
    COUNT(DISTINCT p.id) AS post_cnt,
    AVG(p.score) AS avg_score,
    AVG(p.viewcount) AS avg_viewcount,
    AVG(COALESCE(phc.hist_count, 0)) AS avg_hist_per_post,
    AVG(COALESCE(phc.distinct_user_hist, 0)) AS avg_distinct_user_hist_per_post,
    MAX(p.answercount) AS max_answercount
FROM posts p
LEFT JOIN post_hist_counts phc
    ON phc.post_id = p.id
GROUP BY p.posttypeid
ORDER BY p.posttypeid
