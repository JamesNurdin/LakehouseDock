SELECT
    t.id AS tag_id,
    t.name AS tag_name,
    tc.name AS tag_class_name,
    COUNT(*) AS total_likes,
    COUNT(DISTINCT c.id) AS distinct_comments_liked,
    COUNT(DISTINCT p.id) AS distinct_likers,
    SUM(CASE WHEN p.gender = 'male' THEN 1 ELSE 0 END) AS male_likers,
    SUM(CASE WHEN p.gender = 'female' THEN 1 ELSE 0 END) AS female_likers,
    SUM(CASE WHEN p.gender NOT IN ('male','female') THEN 1 ELSE 0 END) AS other_gender_likers
FROM comment_has_tag_tag cht
JOIN comment c
    ON cht.comment_id = c.id
JOIN tag t
    ON cht.tag_id = t.id
JOIN tag_class tc
    ON t.type_tag_class_id = tc.id
JOIN person_likes_comment plc
    ON plc.comment_id = c.id
JOIN person p
    ON plc.person_id = p.id
GROUP BY t.id, t.name, tc.name
ORDER BY total_likes DESC
LIMIT 10
