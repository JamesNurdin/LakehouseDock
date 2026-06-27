WITH post_comment_stats AS (
    SELECT
        p.id AS post_id,
        p.posttypeid AS post_typeid,
        p.owneruserid,
        p.creationdate AS post_creationdate,
        p.score AS post_score,
        p.viewcount,
        p.answercount,
        p.commentcount AS post_commentcount,
        p.favoritecount,
        p.lasteditoruserid,
        COUNT(c.id) AS comment_count,
        SUM(c.score) AS comment_score_sum,
        AVG(c.score) AS comment_score_avg,
        MIN(c.creationdate) AS first_comment_date,
        MAX(c.creationdate) AS last_comment_date
    FROM stats_ceb_sf1.posts p
    LEFT JOIN stats_ceb_sf1.comments c
        ON c.postid = p.id
    WHERE p.posttypeid = 1
    GROUP BY
        p.id,
        p.posttypeid,
        p.owneruserid,
        p.creationdate,
        p.score,
        p.viewcount,
        p.answercount,
        p.commentcount,
        p.favoritecount,
        p.lasteditoruserid
)
SELECT
    post_id,
    post_typeid,
    owneruserid,
    post_creationdate,
    post_score,
    viewcount,
    answercount,
    post_commentcount,
    comment_count,
    comment_score_sum,
    comment_score_avg,
    CASE WHEN post_score <> 0 THEN comment_score_sum / post_score ELSE NULL END AS comment_to_post_score_ratio,
    date_diff('day', post_creationdate, last_comment_date) AS days_to_last_comment
FROM post_comment_stats
WHERE comment_count > 0
ORDER BY comment_to_post_score_ratio DESC
LIMIT 100
