WITH direct_counts AS (
    SELECT
        tc.id AS tag_class_id,
        tc.name AS tag_class_name,
        COUNT(t.id) AS direct_tag_count,
        AVG(length(t.name)) AS avg_tag_name_length
    FROM tag_class AS tc
    LEFT JOIN tag AS t
        ON t.type_tag_class_id = tc.id
    GROUP BY tc.id, tc.name
),
child_counts AS (
    SELECT
        parent.id AS parent_tag_class_id,
        parent.name AS parent_tag_class_name,
        COUNT(t.id) AS child_tag_count
    FROM tag_class AS parent
    LEFT JOIN tag_class AS child
        ON child.subclass_of_tag_class_id = parent.id
    LEFT JOIN tag AS t
        ON t.type_tag_class_id = child.id
    GROUP BY parent.id, parent.name
)
SELECT
    dc.tag_class_id,
    dc.tag_class_name,
    dc.direct_tag_count,
    COALESCE(cc.child_tag_count, 0) AS child_tag_count,
    dc.direct_tag_count + COALESCE(cc.child_tag_count, 0) AS total_tag_count,
    dc.avg_tag_name_length
FROM direct_counts AS dc
LEFT JOIN child_counts AS cc
    ON cc.parent_tag_class_id = dc.tag_class_id
ORDER BY total_tag_count DESC, dc.tag_class_name
LIMIT 10
