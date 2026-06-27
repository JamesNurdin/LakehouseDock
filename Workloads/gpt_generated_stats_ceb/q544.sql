WITH post_history_summary AS (
    SELECT
        p.id AS post_id,
        p.posttypeid,
        p.owneruserid,
        p.creationdate AS post_creationdate,
        p.score,
        p.viewcount,
        p.answercount,
        p.commentcount,
        p.favoritecount,
        p.lasteditoruserid,
        COUNT(ph.id) AS history_event_count,
        COUNT(DISTINCT ph.userid) AS distinct_user_count,
        MIN(ph.creationdate) AS first_history_date,
        MAX(ph.creationdate) AS last_history_date
    FROM posts p
    LEFT JOIN posthistory ph
        ON ph.posthistorytypeid = p.id
    GROUP BY p.id, p.posttypeid, p.owneruserid, p.creationdate, p.score, p.viewcount, p.answercount, p.commentcount, p.favoritecount, p.lasteditoruserid
)
SELECT
    posttypeid,
    COUNT(post_id) AS total_posts,
    SUM(score) AS total_score,
    AVG(score) AS avg_score,
    AVG(viewcount) AS avg_viewcount,
    AVG(answercount) AS avg_answercount,
    AVG(commentcount) AS avg_commentcount,
    AVG(favoritecount) AS avg_favoritecount,
    SUM(history_event_count) AS total_history_events,
    AVG(history_event_count) AS avg_history_events_per_post,
    AVG(distinct_user_count) AS avg_distinct_users_per_post,
    MIN(post_creationdate) AS earliest_post_date,
    MAX(post_creationdate) AS latest_post_date,
    MIN(first_history_date) AS earliest_history_date,
    MAX(last_history_date) AS latest_history_date
FROM post_history_summary
WHERE history_event_count > 0
GROUP BY posttypeid
ORDER BY total_posts DESC
