WITH joined AS (
    SELECT
        p.id AS post_id,
        p.owneruserid,
        p.posttypeid,
        p.creationdate AS post_creationdate,
        p.score,
        p.viewcount,
        p.answercount,
        p.commentcount,
        p.favoritecount,
        p.lasteditoruserid,
        ph.id AS posthistory_id,
        ph.creationdate AS posthistory_creationdate,
        ph.userid AS posthistory_userid
    FROM posts p
    JOIN posthistory ph
        ON ph.posthistorytypeid = p.id
)
SELECT
    j.owneruserid,
    j.posttypeid,
    COUNT(DISTINCT j.post_id) AS num_posts,
    COUNT(j.posthistory_id) AS num_posthistory_entries,
    AVG(j.score) AS avg_score,
    SUM(j.viewcount) AS total_views,
    AVG(j.answercount) AS avg_answers,
    AVG(j.commentcount) AS avg_comments,
    AVG(j.favoritecount) AS avg_favorites,
    AVG(date_diff('day', j.post_creationdate, j.posthistory_creationdate)) AS avg_days_to_history
FROM joined j
GROUP BY j.owneruserid, j.posttypeid
ORDER BY total_views DESC
LIMIT 10
