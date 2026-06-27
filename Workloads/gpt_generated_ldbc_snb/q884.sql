SELECT
    tc.id AS tag_class_id,
    tc.name AS tag_class_name,
    pc.id AS parent_tag_class_id,
    pc.name AS parent_tag_class_name,
    COUNT(*) AS tag_assignments,
    COUNT(DISTINCT pht.post_id) AS distinct_posts,
    MIN(pht.creation_date) AS earliest_tag_assignment,
    MAX(pht.creation_date) AS latest_tag_assignment
FROM post_has_tag_tag AS pht
JOIN tag AS t
    ON pht.tag_id = t.id
JOIN tag_class AS tc
    ON t.type_tag_class_id = tc.id
LEFT JOIN tag_class AS pc
    ON tc.subclass_of_tag_class_id = pc.id
GROUP BY
    tc.id,
    tc.name,
    pc.id,
    pc.name
ORDER BY tag_assignments DESC
LIMIT 100
