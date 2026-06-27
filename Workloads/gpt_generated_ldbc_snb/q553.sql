WITH forum_tag_person AS (
    SELECT
        f.id AS forum_id,
        t.id AS tag_id,
        tc_child.id AS child_class_id,
        tc_child.name AS child_class_name,
        tc_parent.id AS parent_class_id,
        tc_parent.name AS parent_class_name,
        pht.person_id AS person_id
    FROM forum f
    JOIN forum_has_tag_tag fht ON fht.forum_id = f.id
    JOIN tag t ON fht.tag_id = t.id
    JOIN tag_class tc_child ON t.type_tag_class_id = tc_child.id
    LEFT JOIN tag_class tc_parent ON tc_child.subclass_of_tag_class_id = tc_parent.id
    JOIN person_has_interest_tag pht ON pht.tag_id = t.id
)
SELECT
    parent_class_name,
    COUNT(DISTINCT forum_id) AS forum_count,
    COUNT(DISTINCT person_id) AS person_count,
    COUNT(DISTINCT tag_id) AS distinct_tag_count
FROM forum_tag_person
GROUP BY parent_class_name
ORDER BY forum_count DESC
LIMIT 10
