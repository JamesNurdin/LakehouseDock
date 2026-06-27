WITH post_link_counts AS (
    SELECT
        p.id AS post_id,
        p.owneruserid,
        p.score,
        u.reputation,
        COUNT(pl.id) AS total_links,
        COUNT(CASE WHEN pl.linktypeid = 1 THEN 1 END) AS type1_links
    FROM posts p
    LEFT JOIN postlinks pl ON pl.postid = p.id
    LEFT JOIN users u ON p.owneruserid = u.id
    GROUP BY p.id, p.owneruserid, p.score, u.reputation
)
SELECT
    FLOOR(reputation / 1000) * 1000 AS reputation_bracket,
    COUNT(*) AS post_count,
    AVG(score) AS avg_score,
    AVG(total_links) AS avg_total_links,
    AVG(type1_links) AS avg_type1_links
FROM post_link_counts
GROUP BY FLOOR(reputation / 1000) * 1000
ORDER BY avg_score DESC
LIMIT 10
