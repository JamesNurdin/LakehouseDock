WITH post_metrics AS (
    SELECT
        p.id AS post_id,
        p.posttypeid,
        p.creationdate AS post_creationdate,
        p.score AS post_score,
        p.viewcount,
        p.owneruserid,
        p.lasteditoruserid,
        COUNT(DISTINCT c.id) AS comment_count,
        COALESCE(SUM(c.score), 0) AS comment_score_sum,
        COUNT(DISTINCT ph.id) AS posthistory_count,
        COUNT(DISTINCT pl_out.id) AS outgoing_link_count,
        COUNT(DISTINCT pl_in.id) AS incoming_link_count
    FROM posts p
    LEFT JOIN comments c
        ON c.postid = p.id
    LEFT JOIN posthistory ph
        ON ph.posthistorytypeid = p.id
    LEFT JOIN postlinks pl_out
        ON pl_out.postid = p.id
    LEFT JOIN postlinks pl_in
        ON pl_in.relatedpostid = p.id
    GROUP BY
        p.id,
        p.posttypeid,
        p.creationdate,
        p.score,
        p.viewcount,
        p.owneruserid,
        p.lasteditoruserid
)
SELECT
    pm.post_id,
    pm.posttypeid,
    pm.post_creationdate,
    pm.post_score,
    pm.viewcount,
    pm.comment_count,
    pm.comment_score_sum,
    pm.posthistory_count,
    pm.outgoing_link_count,
    pm.incoming_link_count,
    u_owner.reputation AS owner_reputation,
    u_editor.reputation AS last_editor_reputation
FROM post_metrics pm
LEFT JOIN users u_owner
    ON u_owner.id = pm.owneruserid
LEFT JOIN users u_editor
    ON u_editor.id = pm.lasteditoruserid
ORDER BY pm.comment_score_sum DESC
LIMIT 100
