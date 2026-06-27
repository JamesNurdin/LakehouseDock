WITH tag_hierarchy AS (
    SELECT
        t.id AS tag_id,
        t.name AS tag_name,
        tc.id AS tag_class_id,
        tc.name AS tag_class_name,
        p_tc.id AS parent_class_id,
        p_tc.name AS parent_class_name
    FROM tag t
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
    LEFT JOIN tag_class p_tc ON tc.subclass_of_tag_class_id = p_tc.id
)
SELECT
    th.tag_class_name,
    th.parent_class_name,
    COUNT(DISTINCT cht.comment_id) AS comment_tagged_count,
    COUNT(DISTINCT fht.forum_id) AS forum_tagged_count,
    COUNT(DISTINCT th.tag_id) AS distinct_tags_used,
    COUNT(DISTINCT cht.comment_id) / NULLIF(COUNT(DISTINCT fht.forum_id), 0) AS comment_to_forum_ratio
FROM tag_hierarchy th
LEFT JOIN comment_has_tag_tag cht ON cht.tag_id = th.tag_id
LEFT JOIN forum_has_tag_tag fht ON fht.tag_id = th.tag_id
GROUP BY
    th.tag_class_name,
    th.parent_class_name
ORDER BY comment_tagged_count DESC
LIMIT 20
