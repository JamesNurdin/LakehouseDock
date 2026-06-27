WITH comment_counts AS (
    SELECT
        c.postid AS post_id,
        COUNT(*) AS comment_cnt
    FROM comments c
    GROUP BY c.postid
),
vote_counts AS (
    SELECT
        v.postid AS post_id,
        COUNT(*) AS vote_cnt
    FROM votes v
    GROUP BY v.postid
),
posthistory_counts AS (
    SELECT
        ph.posthistorytypeid AS post_id,
        COUNT(*) AS ph_cnt
    FROM posthistory ph
    GROUP BY ph.posthistorytypeid
),
outbound_links AS (
    SELECT
        pl.postid AS post_id,
        COUNT(*) AS out_link_cnt
    FROM postlinks pl
    GROUP BY pl.postid
),
inbound_links AS (
    SELECT
        pl.relatedpostid AS post_id,
        COUNT(*) AS in_link_cnt
    FROM postlinks pl
    GROUP BY pl.relatedpostid
),
tag_counts AS (
    SELECT
        t.excerptpostid AS post_id,
        COUNT(*) AS tag_cnt
    FROM tags t
    GROUP BY t.excerptpostid
)
SELECT
    date_trunc('month', p.creationdate) AS month,
    p.posttypeid AS post_type,
    COUNT(*) AS total_posts,
    SUM(p.score) AS total_score,
    AVG(p.score) AS avg_score,
    SUM(COALESCE(cc.comment_cnt, 0)) AS total_comments,
    SUM(COALESCE(vc.vote_cnt, 0)) AS total_votes,
    SUM(COALESCE(phc.ph_cnt, 0)) AS total_posthistory_entries,
    SUM(COALESCE(ol.out_link_cnt, 0)) AS total_outbound_links,
    SUM(COALESCE(il.in_link_cnt, 0)) AS total_inbound_links,
    SUM(COALESCE(tc.tag_cnt, 0)) AS total_tags,
    AVG(u_owner.reputation) AS avg_owner_reputation,
    AVG(u_editor.reputation) AS avg_editor_reputation
FROM posts p
LEFT JOIN comment_counts cc ON cc.post_id = p.id
LEFT JOIN vote_counts vc ON vc.post_id = p.id
LEFT JOIN posthistory_counts phc ON phc.post_id = p.id
LEFT JOIN outbound_links ol ON ol.post_id = p.id
LEFT JOIN inbound_links il ON il.post_id = p.id
LEFT JOIN tag_counts tc ON tc.post_id = p.id
LEFT JOIN users u_owner ON u_owner.id = p.owneruserid
LEFT JOIN users u_editor ON u_editor.id = p.lasteditoruserid
GROUP BY
    date_trunc('month', p.creationdate),
    p.posttypeid
ORDER BY
    month DESC,
    post_type
