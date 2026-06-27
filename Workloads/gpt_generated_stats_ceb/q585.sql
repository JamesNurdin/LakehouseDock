WITH post_votes AS (
    SELECT
        v.postid AS post_id,
        COUNT(*) AS vote_count,
        COUNT(DISTINCT v.userid) AS distinct_voter_count
    FROM votes v
    GROUP BY v.postid
),
post_edits AS (
    SELECT
        ph.posthistorytypeid AS post_id,
        COUNT(*) AS edit_count
    FROM posthistory ph
    GROUP BY ph.posthistorytypeid
),
post_outgoing_links AS (
    SELECT
        pl.postid AS post_id,
        COUNT(*) AS outgoing_link_count
    FROM postlinks pl
    GROUP BY pl.postid
),
post_incoming_links AS (
    SELECT
        pl.relatedpostid AS post_id,
        COUNT(*) AS incoming_link_count
    FROM postlinks pl
    GROUP BY pl.relatedpostid
),
post_tags AS (
    SELECT
        t.excerptpostid AS post_id,
        t.id AS tag_id,
        t.count AS tag_use_count
    FROM tags t
),
post_owners AS (
    SELECT
        p.id AS post_id,
        p.posttypeid,
        p.creationdate,
        p.score,
        p.viewcount,
        p.answercount,
        p.commentcount,
        p.favoritecount,
        p.owneruserid,
        p.lasteditoruserid,
        u_owner.reputation AS owner_reputation,
        u_owner.creationdate AS owner_creationdate,
        u_editor.reputation AS last_editor_reputation,
        u_editor.creationdate AS last_editor_creationdate
    FROM posts p
    LEFT JOIN users u_owner ON p.owneruserid = u_owner.id
    LEFT JOIN users u_editor ON p.lasteditoruserid = u_editor.id
)
SELECT
    po.post_id,
    po.posttypeid,
    po.creationdate,
    po.score,
    po.viewcount,
    po.answercount,
    po.commentcount,
    po.favoritecount,
    po.owneruserid,
    po.lasteditoruserid,
    po.owner_reputation,
    po.owner_creationdate,
    po.last_editor_reputation,
    po.last_editor_creationdate,
    COALESCE(pv.vote_count, 0) AS vote_count,
    COALESCE(pv.distinct_voter_count, 0) AS distinct_voter_count,
    COALESCE(pe.edit_count, 0) AS edit_count,
    COALESCE(pol.outgoing_link_count, 0) AS outgoing_link_count,
    COALESCE(pil.incoming_link_count, 0) AS incoming_link_count,
    pt.tag_id,
    pt.tag_use_count
FROM post_owners po
LEFT JOIN post_votes pv ON pv.post_id = po.post_id
LEFT JOIN post_edits pe ON pe.post_id = po.post_id
LEFT JOIN post_outgoing_links pol ON pol.post_id = po.post_id
LEFT JOIN post_incoming_links pil ON pil.post_id = po.post_id
LEFT JOIN post_tags pt ON pt.post_id = po.post_id
ORDER BY vote_count DESC, edit_count DESC
LIMIT 100
