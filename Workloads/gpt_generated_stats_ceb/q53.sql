WITH inbound_links AS (
    SELECT
        pl.relatedpostid,
        COUNT(*) AS inbound_link_count,
        COUNT(DISTINCT pl.linktypeid) AS distinct_inbound_linktype_count
    FROM postlinks pl
    GROUP BY pl.relatedpostid
),
outbound_links AS (
    SELECT
        pl.postid,
        COUNT(*) AS outbound_link_count,
        COUNT(DISTINCT pl.linktypeid) AS distinct_outbound_linktype_count
    FROM postlinks pl
    GROUP BY pl.postid
)
SELECT
    p.posttypeid,
    COUNT(*) AS post_count,
    AVG(p.score) AS avg_score,
    SUM(p.viewcount) AS total_viewcount,
    SUM(COALESCE(il.inbound_link_count, 0)) AS total_inbound_links,
    SUM(COALESCE(ol.outbound_link_count, 0)) AS total_outbound_links,
    SUM(COALESCE(il.distinct_inbound_linktype_count, 0)) AS total_distinct_inbound_linktypes,
    SUM(COALESCE(ol.distinct_outbound_linktype_count, 0)) AS total_distinct_outbound_linktypes
FROM posts p
LEFT JOIN inbound_links il ON il.relatedpostid = p.id
LEFT JOIN outbound_links ol ON ol.postid = p.id
GROUP BY p.posttypeid
ORDER BY p.posttypeid
