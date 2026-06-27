WITH comment_tag AS (
    SELECT
        cht.comment_id,
        cht.tag_id
    FROM comment_has_tag_tag AS cht
),

tag_class_hierarchy AS (
    SELECT
        tc.id,
        tc.name,
        tc.subclass_of_tag_class_id,
        parent_tc.id AS parent_id,
        parent_tc.name AS parent_name
    FROM tag_class AS tc
    LEFT JOIN tag_class AS parent_tc
        ON tc.subclass_of_tag_class_id = parent_tc.id
)
SELECT
    tc.id AS tag_class_id,
    tc.name AS tag_class_name,
    tc.parent_id,
    tc.parent_name,
    COUNT(DISTINCT ct.comment_id) AS distinct_comment_count,
    COUNT(DISTINCT ct.tag_id) AS distinct_tag_count,
    COUNT(*) AS total_tag_assignments,
    CAST(COUNT(*) AS DOUBLE) / NULLIF(COUNT(DISTINCT ct.comment_id), 0) AS avg_tags_per_comment
FROM comment_tag AS ct
JOIN tag AS t
    ON ct.tag_id = t.id
JOIN tag_class_hierarchy AS tc
    ON t.type_tag_class_id = tc.id
GROUP BY
    tc.id,
    tc.name,
    tc.parent_id,
    tc.parent_name
ORDER BY total_tag_assignments DESC
LIMIT 50
