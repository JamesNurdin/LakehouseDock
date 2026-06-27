WITH post_votes AS (
    SELECT postid, COUNT(*) AS vote_count
    FROM votes
    GROUP BY postid
),
post_outbound_links AS (
    SELECT postid, COUNT(*) AS outbound_link_count
    FROM postlinks
    GROUP BY postid
),
post_inbound_links AS (
    SELECT relatedpostid AS postid, COUNT(*) AS inbound_link_count
    FROM postlinks
    GROUP BY relatedpostid
),
post_tags AS (
    SELECT excerptpostid AS postid, COUNT(*) AS tag_count
    FROM tags
    GROUP BY excerptpostid
),
post_rel_scores AS (
    SELECT pl.postid AS postid, AVG(p2.score) AS avg_related_score
    FROM postlinks pl
    JOIN posts p2 ON pl.relatedpostid = p2.id
    GROUP BY pl.postid
)
SELECT
    p.id AS post_id,
    p.creationdate,
    p.score,
    p.viewcount,
    p.owneruserid,
    p.answercount,
    p.commentcount,
    p.favoritecount,
    p.lasteditoruserid,
    COALESCE(v.vote_count, 0) AS total_votes,
    COALESCE(ol.outbound_link_count, 0) AS outbound_links,
    COALESCE(il.inbound_link_count, 0) AS inbound_links,
    COALESCE(t.tag_count, 0) AS tag_count,
    COALESCE(rs.avg_related_score, 0.0) AS avg_related_score
FROM posts p
LEFT JOIN post_votes v ON v.postid = p.id
LEFT JOIN post_outbound_links ol ON ol.postid = p.id
LEFT JOIN post_inbound_links il ON il.postid = p.id
LEFT JOIN post_tags t ON t.postid = p.id
LEFT JOIN post_rel_scores rs ON rs.postid = p.id
ORDER BY p.score DESC, total_votes DESC
LIMIT 10
