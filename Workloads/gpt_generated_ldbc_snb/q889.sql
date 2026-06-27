SELECT
    pc.name AS city_name,
    tc.name AS tag_class_name,
    COUNT(DISTINCT c.id) AS num_comments,
    AVG(c.length) AS avg_comment_length,
    COUNT(plc.person_id) AS total_likes,
    COUNT(DISTINCT plc.person_id) AS distinct_likers,
    COUNT(DISTINCT p.id) AS distinct_comment_authors
FROM comment c
JOIN person p ON c.creator_person_id = p.id
JOIN place pc ON p.location_city_id = pc.id
JOIN comment_has_tag_tag cht ON cht.comment_id = c.id
JOIN tag t ON cht.tag_id = t.id
JOIN tag_class tc ON t.type_tag_class_id = tc.id
LEFT JOIN person_likes_comment plc ON plc.comment_id = c.id
GROUP BY pc.name, tc.name
ORDER BY num_comments DESC
LIMIT 100
