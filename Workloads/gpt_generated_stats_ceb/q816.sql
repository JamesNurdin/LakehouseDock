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
    FROM posthistory ph
    JOIN posts p
        ON ph.posthistorytypeid = p.id
)
SELECT
    post_id,
    posttypeid,
    date_trunc('month', post_creationdate) AS month,
    COUNT(*) AS history_event_count,
    COUNT(DISTINCT ph_userid) AS distinct_user_count,
    SUM(score) AS total_score,
    AVG(answercount) AS avg_answer_count,
    MAX(viewcount) AS max_view_count,
    MIN(post_creationdate) AS earliest_post_creation
FROM ph_posts
GROUP BY post_id, posttypeid, date_trunc('month', post_creationdate)
ORDER BY month DESC, history_event_count DESC
