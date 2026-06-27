WITH comment_agg AS (
    SELECT
        postid AS post_id,
        COUNT(*) AS comment_cnt,
        SUM(score) AS comment_score_sum
    FROM comments
    GROUP BY postid
),
posthistory_agg AS (
    SELECT
        posthistorytypeid AS post_id,
        COUNT(*) AS posthistory_cnt
    FROM posthistory
    GROUP BY posthistorytypeid
),
postlink_agg AS (
    SELECT
        post_id,
        COUNT(*) AS postlink_cnt
    FROM (
        SELECT postid AS post_id FROM postlinks
        UNION ALL
        SELECT relatedpostid AS post_id FROM postlinks
    ) pl
    GROUP BY post_id
)
SELECT
    date_trunc('day', p.creationdate) AS post_day,
    COUNT(*) AS post_cnt,
    SUM(p.score) AS total_post_score,
    AVG(p.viewcount) AS avg_view_count,
    SUM(p.answercount) AS total_answer_count,
    SUM(p.commentcount) AS total_comment_count,
    COALESCE(SUM(ca.comment_cnt), 0) AS total_comment_events,
    COALESCE(SUM(ca.comment_score_sum), 0) AS total_comment_score,
    COALESCE(SUM(pha.posthistory_cnt), 0) AS total_posthistory_events,
    COALESCE(SUM(pla.postlink_cnt), 0) AS total_postlink_events,
    COALESCE(SUM(u_owner.reputation), 0) AS total_owner_reputation,
    COALESCE(SUM(u_lasteditor.reputation), 0) AS total_last_editor_reputation
FROM posts p
LEFT JOIN comment_agg ca
    ON ca.post_id = p.id
LEFT JOIN posthistory_agg pha
    ON pha.post_id = p.id
LEFT JOIN postlink_agg pla
    ON pla.post_id = p.id
LEFT JOIN users u_owner
    ON u_owner.id = p.owneruserid
LEFT JOIN users u_lasteditor
    ON u_lasteditor.id = p.lasteditoruserid
GROUP BY date_trunc('day', p.creationdate)
ORDER BY post_day
