WITH post_link_stats AS (
    SELECT
        p.id AS post_id,
        p.score,
        p.creationdate,
        p.owneruserid,
        COUNT(DISTINCT pl_out.id) AS out_link_count,
        COUNT(DISTINCT pl_in.id) AS in_link_count,
        COUNT(DISTINCT pl_out.linktypeid) AS out_distinct_linktype,
        COUNT(DISTINCT pl_in.linktypeid) AS in_distinct_linktype
    FROM posts p
    LEFT JOIN postlinks pl_out
        ON pl_out.postid = p.id
    LEFT JOIN postlinks pl_in
        ON pl_in.relatedpostid = p.id
    GROUP BY p.id, p.score, p.creationdate, p.owneruserid
),
tag_post_aggregates AS (
    SELECT
        t.id AS tag_id,
        t.count AS tag_count,
        COUNT(DISTINCT pls.post_id) AS post_count,
        AVG(pls.score) AS avg_post_score,
        SUM(pls.out_link_count) AS total_out_links,
        SUM(pls.in_link_count) AS total_in_links,
        AVG(pls.out_distinct_linktype) AS avg_out_distinct_linktype,
        AVG(pls.in_distinct_linktype) AS avg_in_distinct_linktype
    FROM tags t
    LEFT JOIN post_link_stats pls
        ON pls.post_id = t.excerptpostid
    GROUP BY t.id, t.count
)
SELECT
    tag_id,
    tag_count,
    post_count,
    avg_post_score,
    total_out_links,
    total_in_links,
    avg_out_distinct_linktype,
    avg_in_distinct_linktype
FROM tag_post_aggregates
ORDER BY total_out_links DESC
LIMIT 10
