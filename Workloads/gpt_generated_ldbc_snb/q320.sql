WITH all_tag_uses AS (
    SELECT tag_id, 'comment' AS content_type FROM comment_has_tag_tag
    UNION ALL
    SELECT tag_id, 'forum'   AS content_type FROM forum_has_tag_tag
    UNION ALL
    SELECT tag_id, 'post'    AS content_type FROM post_has_tag_tag
)
SELECT
    COALESCE(parent_tc.name, child_tc.name) AS tag_class_name,
    COUNT(*) FILTER (WHERE at.content_type = 'comment') AS comment_tag_uses,
    COUNT(*) FILTER (WHERE at.content_type = 'forum')   AS forum_tag_uses,
    COUNT(*) FILTER (WHERE at.content_type = 'post')    AS post_tag_uses,
    COUNT(DISTINCT t.id)                              AS distinct_tag_count,
    COUNT(*)                                          AS total_tag_uses
FROM all_tag_uses at
JOIN tag t
    ON at.tag_id = t.id
JOIN tag_class child_tc
    ON t.type_tag_class_id = child_tc.id
LEFT JOIN tag_class parent_tc
    ON child_tc.subclass_of_tag_class_id = parent_tc.id
GROUP BY COALESCE(parent_tc.name, child_tc.name)
ORDER BY total_tag_uses DESC
LIMIT 50
