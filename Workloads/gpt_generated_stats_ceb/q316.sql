/*
   Analytical query: compare inbound and outbound link counts per post type.
   Uses only the postlinks and posts tables and the allowed join rules.
*/
WITH inbound AS (
    SELECT
        p.posttypeid AS posttypeid,
        COUNT(pl.id) AS inbound_links
    FROM postlinks pl
    JOIN posts p ON pl.relatedpostid = p.id
    GROUP BY p.posttypeid
),
outbound AS (
    SELECT
        p.posttypeid AS posttypeid,
        COUNT(pl.id) AS outbound_links
    FROM postlinks pl
    JOIN posts p ON pl.postid = p.id
    GROUP BY p.posttypeid
)
SELECT
    COALESCE(i.posttypeid, o.posttypeid) AS posttypeid,
    i.inbound_links,
    o.outbound_links,
    CASE
        WHEN o.outbound_links IS NULL OR o.outbound_links = 0 THEN NULL
        ELSE i.inbound_links * 1.0 / o.outbound_links
    END AS inbound_outbound_ratio
FROM inbound i
FULL JOIN outbound o ON i.posttypeid = o.posttypeid
ORDER BY inbound_outbound_ratio DESC NULLS LAST
