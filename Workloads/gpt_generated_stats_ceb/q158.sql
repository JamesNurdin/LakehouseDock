WITH ph_posts AS (
    SELECT
        ph.id AS ph_id,
        ph.posthistorytypeid,
        ph.postid AS ph_postid,
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
    FROM posthistory ph
    JOIN posts p
      ON ph.posthistorytypeid = p.id
)
SELECT
    ph_posts.posthistorytypeid,
    COUNT(*) AS history_count,
    COUNT(DISTINCT ph_posts.ph_userid) AS distinct_user_count,
    AVG(ph_posts.score) AS avg_post_score,
    SUM(ph_posts.viewcount) AS total_viewcount,
    MAX(ph_posts.commentcount) AS max_commentcount,
    MIN(ph_posts.ph_creationdate) AS earliest_history_creationdate,
    MAX(ph_posts.ph_creationdate) AS latest_history_creationdate,
    AVG(date_diff('day', CAST(ph_posts.post_creationdate AS date), CAST(ph_posts.ph_creationdate AS date))) AS avg_history_lag_days
FROM ph_posts
GROUP BY ph_posts.posthistorytypeid
ORDER BY history_count DESC
LIMIT 10
