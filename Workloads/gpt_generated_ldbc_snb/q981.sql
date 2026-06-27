SELECT
    t.id AS tag_id,
    t.name AS tag_name,
    COUNT(*) AS comment_count,
    COUNT(DISTINCT p.id) AS distinct_commenters,
    AVG(c.length) AS avg_comment_length,
    SUM(CASE WHEN c.parent_comment_id IS NOT NULL THEN 1 ELSE 0 END) AS reply_comments,
    SUM(CASE WHEN c.parent_comment_id IS NOT NULL THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) AS reply_ratio,
    AVG(pc.length) AS avg_parent_comment_length
FROM comment_has_tag_tag cht
JOIN comment c
    ON cht.comment_id = c.id
JOIN tag t
    ON cht.tag_id = t.id
JOIN person p
    ON c.creator_person_id = p.id
LEFT JOIN comment pc
    ON c.parent_comment_id = pc.id
GROUP BY t.id, t.name
ORDER BY comment_count DESC
LIMIT 10
