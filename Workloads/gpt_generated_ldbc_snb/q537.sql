SELECT
    tc.id AS tag_class_id,
    tc.name AS tag_class_name,
    parent_tc.name AS parent_tag_class_name,
    COUNT(DISTINCT p.id) AS post_count,
    COUNT(DISTINCT c.id) AS comment_count,
    COUNT(DISTINCT plc.person_id) AS distinct_likers,
    AVG(p.length) AS avg_post_length,
    AVG(c.length) AS avg_comment_length
FROM tag_class AS tc
LEFT JOIN tag_class AS parent_tc
    ON tc.subclass_of_tag_class_id = parent_tc.id
LEFT JOIN tag AS t
    ON t.type_tag_class_id = tc.id
LEFT JOIN post_has_tag_tag AS pht
    ON pht.tag_id = t.id
LEFT JOIN post AS p
    ON p.id = pht.post_id
LEFT JOIN comment_has_tag_tag AS cht
    ON cht.tag_id = t.id
LEFT JOIN comment AS c
    ON c.id = cht.comment_id
LEFT JOIN person_likes_comment AS plc
    ON plc.comment_id = c.id
GROUP BY
    tc.id,
    tc.name,
    parent_tc.name
ORDER BY post_count DESC
LIMIT 10
