SELECT
    t.name AS tag_name,
    COUNT(c.id) AS total_comments,
    AVG(c.length) AS avg_comment_length,
    AVG(p.length) FILTER (WHERE p.length IS NOT NULL) AS avg_parent_comment_length,
    SUM(CASE WHEN c.parent_comment_id IS NOT NULL THEN 1 ELSE 0 END) AS reply_comments,
    SUM(CASE WHEN c.parent_comment_id IS NULL THEN 1 ELSE 0 END) AS top_level_comments
FROM comment AS c
LEFT JOIN comment AS p
    ON c.parent_comment_id = p.id
JOIN comment_has_tag_tag AS cht
    ON cht.comment_id = c.id
JOIN tag AS t
    ON t.id = cht.tag_id
GROUP BY t.id, t.name
ORDER BY total_comments DESC
LIMIT 20
