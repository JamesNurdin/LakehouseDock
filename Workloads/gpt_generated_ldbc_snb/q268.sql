WITH unified_tags AS (
    SELECT CAST('comment' AS varchar) AS entity_type,
           comment_id AS entity_id,
           tag_id,
           creation_date
    FROM comment_has_tag_tag
    UNION ALL
    SELECT CAST('forum' AS varchar) AS entity_type,
           forum_id AS entity_id,
           tag_id,
           creation_date
    FROM forum_has_tag_tag
    UNION ALL
    SELECT CAST('post' AS varchar) AS entity_type,
           post_id AS entity_id,
           tag_id,
           creation_date
    FROM post_has_tag_tag
)
SELECT
    tc.id AS tag_class_id,
    tc.name AS tag_class_name,
    parent_tc.id AS parent_tag_class_id,
    parent_tc.name AS parent_tag_class_name,
    COUNT(*) AS total_tag_assignments,
    COUNT(DISTINCT t.id) AS distinct_tags_used,
    COUNT(CASE WHEN ut.entity_type = 'comment' THEN 1 END) AS comment_tag_assignments,
    COUNT(CASE WHEN ut.entity_type = 'forum' THEN 1 END) AS forum_tag_assignments,
    COUNT(CASE WHEN ut.entity_type = 'post' THEN 1 END) AS post_tag_assignments,
    COUNT(CASE WHEN ut.entity_type = 'comment' THEN 1 END) * 1.0 / COUNT(*) AS comment_ratio,
    COUNT(CASE WHEN ut.entity_type = 'forum' THEN 1 END) * 1.0 / COUNT(*) AS forum_ratio,
    COUNT(CASE WHEN ut.entity_type = 'post' THEN 1 END) * 1.0 / COUNT(*) AS post_ratio
FROM unified_tags ut
JOIN tag t
    ON ut.tag_id = t.id
JOIN tag_class tc
    ON t.type_tag_class_id = tc.id
LEFT JOIN tag_class parent_tc
    ON tc.subclass_of_tag_class_id = parent_tc.id
GROUP BY tc.id, tc.name, parent_tc.id, parent_tc.name
ORDER BY total_tag_assignments DESC
LIMIT 20
