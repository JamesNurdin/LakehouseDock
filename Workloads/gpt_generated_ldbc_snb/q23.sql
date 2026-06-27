SELECT
    tc.name AS tag_class_name,
    parent_tc.name AS parent_class_name,
    COUNT(DISTINCT f.id) AS forum_count,
    COUNT(DISTINCT pht.post_id) AS post_count,
    COUNT(DISTINCT cht.comment_id) AS comment_count,
    COUNT(DISTINCT pit.person_id) AS person_interest_count
FROM tag t
JOIN tag_class tc ON t.type_tag_class_id = tc.id
LEFT JOIN tag_class parent_tc ON tc.subclass_of_tag_class_id = parent_tc.id
LEFT JOIN forum_has_tag_tag fht ON fht.tag_id = t.id
LEFT JOIN forum f ON fht.forum_id = f.id
LEFT JOIN post_has_tag_tag pht ON pht.tag_id = t.id
LEFT JOIN comment_has_tag_tag cht ON cht.tag_id = t.id
LEFT JOIN person_has_interest_tag pit ON pit.tag_id = t.id
GROUP BY
    tc.name,
    parent_tc.name
ORDER BY
    forum_count DESC
LIMIT 100
