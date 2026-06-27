WITH
    post_history_counts AS (
        SELECT
            posthistorytypeid,
            COUNT(*) AS history_count,
            COUNT(DISTINCT userid) AS distinct_history_user_count
        FROM posthistory
        GROUP BY posthistorytypeid
    ),
    post_link_counts AS (
        SELECT
            postid,
            COUNT(*) AS outgoing_link_count
        FROM postlinks
        GROUP BY postid
    ),
    post_link_in_counts AS (
        SELECT
            relatedpostid,
            COUNT(*) AS incoming_link_count
        FROM postlinks
        GROUP BY relatedpostid
    ),
    tag_counts AS (
        SELECT
            excerptpostid,
            COUNT(*) AS tag_count
        FROM tags
        GROUP BY excerptpostid
    ),
    post_owner_editor AS (
        SELECT
            p.id,
            p.posttypeid,
            p.creationdate,
            p.score,
            p.viewcount,
            p.answercount,
            p.commentcount,
            p.favoritecount,
            p.owneruserid,
            p.lasteditoruserid,
            o.reputation AS owner_reputation,
            e.reputation AS editor_reputation
        FROM posts p
        LEFT JOIN users o ON p.owneruserid = o.id
        LEFT JOIN users e ON p.lasteditoruserid = e.id
    )
SELECT
    po.posttypeid,
    COUNT(*) AS total_posts,
    AVG(po.score) AS avg_score,
    SUM(po.viewcount) AS total_viewcount,
    SUM(po.answercount) AS total_answercount,
    SUM(po.commentcount) AS total_commentcount,
    SUM(po.favoritecount) AS total_favoritecount,
    AVG(po.owner_reputation) AS avg_owner_reputation,
    AVG(po.editor_reputation) AS avg_editor_reputation,
    SUM(COALESCE(phc.history_count, 0)) AS total_history_events,
    SUM(COALESCE(phc.distinct_history_user_count, 0)) AS total_distinct_history_users,
    SUM(COALESCE(plc.outgoing_link_count, 0) + COALESCE(pli.incoming_link_count, 0)) AS total_links,
    SUM(COALESCE(tc.tag_count, 0)) AS total_tags
FROM post_owner_editor po
LEFT JOIN post_history_counts phc ON phc.posthistorytypeid = po.id
LEFT JOIN post_link_counts plc ON plc.postid = po.id
LEFT JOIN post_link_in_counts pli ON pli.relatedpostid = po.id
LEFT JOIN tag_counts tc ON tc.excerptpostid = po.id
GROUP BY po.posttypeid
ORDER BY total_posts DESC
