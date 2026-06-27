/*
  Analytical query: Top tags by total post score with associated activity metrics
  (uses only the selected tables and allowed join rules)
*/
WITH tag_posts AS (
    SELECT
        t.id AS tag_id,
        t.count AS tag_count,
        p.id AS post_id,
        p.score AS post_score
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
),
post_votes AS (
    SELECT
        v.postid,
        COUNT(*) AS vote_count,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvote_count,
        SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvote_count
    FROM votes v
    GROUP BY v.postid
),
post_comments AS (
    SELECT
        c.postid,
        COUNT(*) AS comment_count
    FROM comments c
    GROUP BY c.postid
),
post_outbound_links AS (
    SELECT
        pl.postid,
        COUNT(*) AS outbound_link_count
    FROM postlinks pl
    GROUP BY pl.postid
),
post_inbound_links AS (
    SELECT
        pl.relatedpostid,
        COUNT(*) AS inbound_link_count
    FROM postlinks pl
    GROUP BY pl.relatedpostid
),
post_edits AS (
    SELECT
        ph.posthistorytypeid AS post_id,
        COUNT(*) AS edit_count
    FROM posthistory ph
    GROUP BY ph.posthistorytypeid
)
SELECT
    tp.tag_id,
    tp.tag_count,
    COUNT(DISTINCT tp.post_id) AS num_posts,
    SUM(tp.post_score) AS total_post_score,
    AVG(tp.post_score) AS avg_post_score,
    COALESCE(SUM(pv.vote_count), 0) AS total_votes,
    COALESCE(SUM(pv.upvote_count), 0) AS total_upvotes,
    COALESCE(SUM(pv.downvote_count), 0) AS total_downvotes,
    COALESCE(SUM(pc.comment_count), 0) AS total_comments,
    COALESCE(SUM(pol.outbound_link_count), 0) AS total_outbound_links,
    COALESCE(SUM(pil.inbound_link_count), 0) AS total_inbound_links,
    COALESCE(SUM(pe.edit_count), 0) AS total_edits
FROM tag_posts tp
LEFT JOIN post_votes pv ON tp.post_id = pv.postid
LEFT JOIN post_comments pc ON tp.post_id = pc.postid
LEFT JOIN post_outbound_links pol ON tp.post_id = pol.postid
LEFT JOIN post_inbound_links pil ON tp.post_id = pil.relatedpostid
LEFT JOIN post_edits pe ON tp.post_id = pe.post_id
GROUP BY tp.tag_id, tp.tag_count
ORDER BY total_post_score DESC
LIMIT 10
