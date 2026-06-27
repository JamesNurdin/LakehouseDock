WITH ph AS (
    SELECT posthistorytypeid AS post_id,
           COUNT(*) AS ph_count
    FROM posthistory
    GROUP BY posthistorytypeid
),
pl_out AS (
    SELECT postid AS post_id,
           COUNT(*) AS outbound_count
    FROM postlinks
    GROUP BY postid
),
pl_in AS (
    SELECT relatedpostid AS post_id,
           COUNT(*) AS inbound_count
    FROM postlinks
    GROUP BY relatedpostid
),
 tg AS (
    SELECT excerptpostid AS post_id,
           COUNT(*) AS tag_count
    FROM tags
    GROUP BY excerptpostid
)
SELECT
    p.posttypeid,
    COUNT(*) AS posts_per_type,
    SUM(p.score) AS total_score,
    AVG(p.score) AS avg_score,
    SUM(p.viewcount) AS total_viewcount,
    AVG(p.viewcount) AS avg_viewcount,
    SUM(p.answercount) AS total_answercount,
    AVG(p.answercount) AS avg_answercount,
    SUM(p.commentcount) AS total_commentcount,
    AVG(p.commentcount) AS avg_commentcount,
    SUM(p.favoritecount) AS total_favoritecount,
    AVG(p.favoritecount) AS avg_favoritecount,
    COALESCE(SUM(ph.ph_count), 0) AS total_posthistory_entries,
    COALESCE(AVG(ph.ph_count), 0) AS avg_posthistory_per_post,
    COALESCE(SUM(pl_out.outbound_count), 0) AS total_outbound_links,
    COALESCE(AVG(pl_out.outbound_count), 0) AS avg_outbound_links_per_post,
    COALESCE(SUM(pl_in.inbound_count), 0) AS total_inbound_links,
    COALESCE(AVG(pl_in.inbound_count), 0) AS avg_inbound_links_per_post,
    COALESCE(SUM(tg.tag_count), 0) AS total_tags,
    COALESCE(AVG(tg.tag_count), 0) AS avg_tags_per_post
FROM posts p
LEFT JOIN ph      ON ph.post_id = p.id
LEFT JOIN pl_out  ON pl_out.post_id = p.id
LEFT JOIN pl_in   ON pl_in.post_id = p.id
LEFT JOIN tg      ON tg.post_id = p.id
GROUP BY p.posttypeid
ORDER BY posts_per_type DESC
