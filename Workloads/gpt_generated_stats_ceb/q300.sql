WITH post_hist AS (
    SELECT
        id AS ph_id,
        posthistorytypeid,
        postid,
        creationdate AS ph_creationdate,
        userid AS ph_userid
    FROM posthistory
),
post_info AS (
    SELECT
        id AS post_id,
        posttypeid,
        creationdate AS post_creationdate,
        score,
        viewcount,
        owneruserid,
        answercount,
        commentcount,
        favoritecount,
        lasteditoruserid
    FROM posts
)
SELECT
    post_info.posttypeid,
    COUNT(post_hist.ph_id) AS history_event_count,
    AVG(post_info.score) AS avg_score,
    SUM(post_info.viewcount) AS total_views,
    AVG(post_info.answercount) AS avg_answer_count,
    MAX(post_info.post_creationdate) AS latest_post_creationdate
FROM post_info
JOIN post_hist
    ON post_hist.posthistorytypeid = post_info.post_id
GROUP BY post_info.posttypeid
ORDER BY history_event_count DESC
LIMIT 10
