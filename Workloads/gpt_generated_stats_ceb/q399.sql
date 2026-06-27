WITH link_stats AS (
    SELECT
        src.id AS source_post_id,
        src.posttypeid AS source_post_type,
        COUNT(*) AS outgoing_link_count,
        COUNT(DISTINCT pl.linktypeid) AS distinct_linktype_count,
        AVG(tgt.score) AS avg_target_score,
        MAX(tgt.creationdate) AS latest_target_creationdate
    FROM postlinks pl
    JOIN posts src
        ON pl.postid = src.id
    JOIN posts tgt
        ON pl.relatedpostid = tgt.id
    GROUP BY src.id, src.posttypeid
)
SELECT
    source_post_id,
    source_post_type,
    outgoing_link_count,
    distinct_linktype_count,
    avg_target_score,
    latest_target_creationdate
FROM link_stats
ORDER BY outgoing_link_count DESC
LIMIT 10
