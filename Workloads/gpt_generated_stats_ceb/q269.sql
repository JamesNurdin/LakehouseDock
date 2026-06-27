WITH post_history_stats AS (
    SELECT
        p.id AS post_id,
        p.posttypeid,
        p.score,
        p.viewcount,
        p.answercount,
        p.creationdate AS post_creationdate,
        ph.id AS ph_id,
        ph.creationdate AS ph_creationdate,
        ph.userid AS ph_userid,
        date_diff('day', p.creationdate, ph.creationdate) AS lag_days
    FROM posthistory ph
    JOIN posts p ON ph.posthistorytypeid = p.id
)
SELECT
    posttypeid,
    COUNT(DISTINCT post_id) AS post_count,
    AVG(score) AS avg_score,
    AVG(viewcount) AS avg_viewcount,
    AVG(answercount) AS avg_answercount,
    AVG(lag_days) AS avg_history_lag_days,
    COUNT(ph_id) AS total_history_events,
    AVG(ph_userid) AS avg_history_userid
FROM post_history_stats
GROUP BY posttypeid
HAVING COUNT(DISTINCT post_id) > 5
ORDER BY posttypeid
