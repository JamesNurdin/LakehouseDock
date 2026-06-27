WITH tag_class_hierarchy AS (
    SELECT
        child.id AS child_tag_class_id,
        child.name AS child_tag_class_name,
        parent.id AS parent_tag_class_id,
        parent.name AS parent_tag_class_name
    FROM tag_class child
    LEFT JOIN tag_class parent
        ON child.subclass_of_tag_class_id = parent.id
)
SELECT
    COALESCE(h.parent_tag_class_id, t.type_tag_class_id) AS top_tag_class_id,
    COALESCE(h.parent_tag_class_name, tc.name) AS top_tag_class_name,
    COUNT(DISTINCT cht.comment_id) AS comment_count,
    COUNT(DISTINCT pht.person_id) AS person_count,
    COUNT(DISTINCT t.id) AS distinct_tag_count
FROM tag t
LEFT JOIN tag_class_hierarchy h
    ON t.type_tag_class_id = h.child_tag_class_id
LEFT JOIN comment_has_tag_tag cht
    ON cht.tag_id = t.id
LEFT JOIN person_has_interest_tag pht
    ON pht.tag_id = t.id
LEFT JOIN tag_class tc
    ON t.type_tag_class_id = tc.id
GROUP BY
    COALESCE(h.parent_tag_class_id, t.type_tag_class_id),
    COALESCE(h.parent_tag_class_name, tc.name)
ORDER BY comment_count DESC
LIMIT 20
