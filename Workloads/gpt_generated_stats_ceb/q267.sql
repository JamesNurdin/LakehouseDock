WITH link_directions AS (
    SELECT
        pl.id AS link_id,
        pl.linktypeid,
        pl.creationdate AS link_creationdate,
        pl.postid AS post_id,
        'outbound' AS direction
    FROM postlinks pl
    UNION ALL
    SELECT
        pl.id AS link_id,
        pl.linktypeid,
        pl.creationdate AS link_creationdate,
        pl.relatedpostid AS post_id,
        'inbound' AS direction
    FROM postlinks pl
)
SELECT
    p.id AS post_id,
    p.posttypeid,
    SUM(CASE WHEN ld.direction = 'outbound' THEN 1 ELSE 0 END) AS outbound_link_count,
    SUM(CASE WHEN ld.direction = 'inbound' THEN 1 ELSE 0 END) AS inbound_link_count,
    COUNT(*) AS total_link_count,
    MIN(ld.link_creationdate) AS earliest_link_date,
    MAX(ld.link_creationdate) AS latest_link_date
FROM posts p
JOIN link_directions ld ON ld.post_id = p.id
GROUP BY p.id, p.posttypeid
ORDER BY total_link_count DESC
LIMIT 50
