SELECT
    phi.person_id,
    tc.id AS tag_class_id,
    tc.name AS tag_class_name,
    COALESCE(ptc.name, 'Root') AS parent_class,
    COUNT(DISTINCT p.id) AS matched_posts,
    AVG(p.length) AS avg_post_length,
    COUNT(DISTINCT p.container_forum_id) AS distinct_forums
FROM person_has_interest_tag phi
JOIN tag t
    ON phi.tag_id = t.id
JOIN tag_class tc
    ON t.type_tag_class_id = tc.id
LEFT JOIN tag_class ptc
    ON tc.subclass_of_tag_class_id = ptc.id
JOIN post_has_tag_tag pht
    ON t.id = pht.tag_id
JOIN post p
    ON pht.post_id = p.id
GROUP BY
    phi.person_id,
    tc.id,
    tc.name,
    COALESCE(ptc.name, 'Root')
ORDER BY matched_posts DESC
LIMIT 100
