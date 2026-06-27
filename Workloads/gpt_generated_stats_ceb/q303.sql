WITH outbound AS (
    SELECT
        pl.postid AS post_id,
        COUNT(*) AS outbound_links,
        COUNT(DISTINCT pl.relatedpostid) AS distinct_outbound_related
    FROM postlinks pl
    GROUP BY pl.postid
),
inbound AS (
    SELECT
        pl.relatedpostid AS post_id,
        COUNT(*) AS inbound_links,
        COUNT(DISTINCT pl.postid) AS distinct_inbound_related
    FROM postlinks pl
    GROUP BY pl.relatedpostid
)
SELECT
    p.id,
    p.score,
    COALESCE(o.outbound_links, 0) AS outbound_links,
    COALESCE(i.inbound_links, 0) AS inbound_links,
    COALESCE(o.distinct_outbound_related, 0) AS distinct_outbound_related,
    COALESCE(i.distinct_inbound_related, 0) AS distinct_inbound_related
FROM posts p
LEFT JOIN outbound o ON p.id = o.post_id
LEFT JOIN inbound i ON p.id = i.post_id
ORDER BY (COALESCE(o.outbound_links, 0) + COALESCE(i.inbound_links, 0)) DESC
LIMIT 20
