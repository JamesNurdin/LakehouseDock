WITH post_metrics AS (
    SELECT
        p.id AS post_id,
        p.creationdate,
        p.owneruserid,
        p.lasteditoruserid,
        p.score AS post_score,
        p.viewcount,
        p.answercount,
        p.commentcount,
        p.favoritecount,
        COUNT(DISTINCT c.id) AS total_comments,
        COUNT(DISTINCT c.userid) AS distinct_commenters,
        COUNT(DISTINCT v.id) AS total_votes,
        COUNT(DISTINCT v.userid) AS distinct_voters,
        SUM(COALESCE(v.bountyamount, 0)) AS total_bounty_amount,
        COUNT(DISTINCT ph.id) AS total_posthistory_events,
        COUNT(DISTINCT pl_out.id) AS total_outbound_links,
        COUNT(DISTINCT pl_in.id) AS total_inbound_links,
        COUNT(DISTINCT t.id) AS total_tags
    FROM posts p
    LEFT JOIN comments c ON c.postid = p.id
    LEFT JOIN votes v ON v.postid = p.id
    LEFT JOIN posthistory ph ON ph.posthistorytypeid = p.id
    LEFT JOIN postlinks pl_out ON pl_out.postid = p.id
    LEFT JOIN postlinks pl_in ON pl_in.relatedpostid = p.id
    LEFT JOIN tags t ON t.excerptpostid = p.id
    GROUP BY
        p.id,
        p.creationdate,
        p.owneruserid,
        p.lasteditoruserid,
        p.score,
        p.viewcount,
        p.answercount,
        p.commentcount,
        p.favoritecount
)
SELECT
    pm.post_id,
    pm.creationdate,
    pm.post_score,
    pm.viewcount,
    pm.answercount,
    pm.commentcount,
    pm.favoritecount,
    u_owner.reputation AS owner_reputation,
    u_editor.reputation AS last_editor_reputation,
    pm.total_comments,
    pm.distinct_commenters,
    pm.total_votes,
    pm.distinct_voters,
    pm.total_bounty_amount,
    pm.total_posthistory_events,
    pm.total_outbound_links,
    pm.total_inbound_links,
    pm.total_tags,
    (pm.viewcount
        + pm.answercount * 10
        + pm.total_comments * 5
        + pm.total_votes * 2
        + pm.total_bounty_amount * 3
        + pm.total_outbound_links * 4
        + pm.total_inbound_links * 4) AS engagement_score
FROM post_metrics pm
LEFT JOIN users u_owner ON u_owner.id = pm.owneruserid
LEFT JOIN users u_editor ON u_editor.id = pm.lasteditoruserid
ORDER BY engagement_score DESC
LIMIT 10
