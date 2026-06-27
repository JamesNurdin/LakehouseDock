WITH post_metrics AS (
    SELECT
        p.id AS post_id,
        p.posttypeid,
        p.creationdate,
        p.score AS post_score,
        p.viewcount,
        p.owneruserid,
        p.lasteditoruserid,
        COALESCE(COUNT(DISTINCT c.id), 0) AS comment_count,
        COALESCE(SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END), 0) AS upvote_count,
        COALESCE(SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END), 0) AS downvote_count,
        COALESCE(COUNT(DISTINCT ph.id), 0) AS history_event_count,
        COALESCE(COUNT(DISTINCT pl_out.id), 0) AS outgoing_link_count,
        COALESCE(COUNT(DISTINCT pl_in.id), 0) AS incoming_link_count,
        COALESCE(COUNT(DISTINCT t.id), 0) AS tag_excerpt_count
    FROM posts p
    LEFT JOIN comments c ON c.postid = p.id
    LEFT JOIN votes v ON v.postid = p.id
    LEFT JOIN posthistory ph ON ph.posthistorytypeid = p.id
    LEFT JOIN postlinks pl_out ON pl_out.postid = p.id
    LEFT JOIN postlinks pl_in ON pl_in.relatedpostid = p.id
    LEFT JOIN tags t ON t.excerptpostid = p.id
    WHERE p.score > 0
    GROUP BY p.id, p.posttypeid, p.creationdate, p.score, p.viewcount, p.owneruserid, p.lasteditoruserid
)
SELECT
    post_id,
    posttypeid,
    creationdate,
    post_score,
    viewcount,
    owneruserid,
    lasteditoruserid,
    comment_count,
    upvote_count,
    downvote_count,
    history_event_count,
    outgoing_link_count,
    incoming_link_count,
    tag_excerpt_count
FROM post_metrics
ORDER BY comment_count DESC
LIMIT 20
