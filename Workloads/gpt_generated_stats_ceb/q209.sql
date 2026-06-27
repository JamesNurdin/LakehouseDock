WITH post_metrics AS (
    SELECT
        posttypeid,
        COUNT(*) AS post_count,
        AVG(score) AS avg_score,
        AVG(viewcount) AS avg_viewcount,
        AVG(answercount) AS avg_answercount,
        AVG(commentcount) AS avg_commentcount,
        AVG(favoritecount) AS avg_favoritecount
    FROM posts
    GROUP BY posttypeid
),
history_counts AS (
    SELECT
        posts.posttypeid,
        COUNT(posthistory.id) AS history_entry_count,
        COUNT(DISTINCT posthistory.userid) AS distinct_user_count,
        MIN(posthistory.creationdate) AS earliest_history_date,
        MAX(posthistory.creationdate) AS latest_history_date
    FROM posthistory
    JOIN posts
        ON posthistory.posthistorytypeid = posts.id
    GROUP BY posts.posttypeid
)
SELECT
    post_metrics.posttypeid,
    post_metrics.post_count,
    post_metrics.avg_score,
    post_metrics.avg_viewcount,
    post_metrics.avg_answercount,
    post_metrics.avg_commentcount,
    post_metrics.avg_favoritecount,
    history_counts.history_entry_count,
    history_counts.distinct_user_count,
    history_counts.earliest_history_date,
    history_counts.latest_history_date
FROM post_metrics
JOIN history_counts
    ON post_metrics.posttypeid = history_counts.posttypeid
ORDER BY post_metrics.posttypeid
