WITH ph_posts AS (
    SELECT
        ph.id AS ph_id,
        ph.posthistorytypeid,
        ph.postid,
        ph.creationdate AS ph_creationdate,
        ph.userid AS ph_userid,
        p.id AS post_id,
        p.posttypeid,
        p.creationdate AS post_creationdate,
        p.score,
        p.viewcount,
        p.owneruserid,
        p.answercount,
        p.commentcount,
        p.favoritecount,
        p.lasteditoruserid
    FROM posthistory AS ph
    JOIN posts AS p
        ON ph.posthistorytypeid = p.id
)
SELECT
    posttypeid,
    COUNT(DISTINCT ph_id) AS posthistory_count,
    COUNT(DISTINCT post_id) AS distinct_posts,
    AVG(score) AS avg_score,
    SUM(viewcount) AS total_views,
    COUNT(DISTINCT ph_userid) AS distinct_history_users,
    MAX(ph_creationdate) AS latest_history_date,
    MIN(ph_creationdate) AS earliest_history_date,
    AVG(date_diff('day', post_creationdate, ph_creationdate)) AS avg_days_between_history_and_post
FROM ph_posts
GROUP BY posttypeid
ORDER BY posthistory_count DESC
LIMIT 10
