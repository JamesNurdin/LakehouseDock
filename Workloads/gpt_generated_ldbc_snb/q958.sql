WITH unified_tags AS (
    SELECT
        tc.id AS tag_class_id,
        tc.name AS tag_class_name,
        p.id AS post_id,
        CAST(NULL AS BIGINT) AS comment_id,
        p.length AS post_length,
        CAST(NULL AS INTEGER) AS comment_length,
        p.creator_person_id AS creator_id,
        p.container_forum_id AS forum_id
    FROM post_has_tag_tag pht
    JOIN post p ON pht.post_id = p.id
    JOIN tag t ON pht.tag_id = t.id
    JOIN tag_class tc ON t.type_tag_class_id = tc.id

    UNION ALL

    SELECT
        tc.id AS tag_class_id,
        tc.name AS tag_class_name,
        CAST(NULL AS BIGINT) AS post_id,
        c.id AS comment_id,
        CAST(NULL AS INTEGER) AS post_length,
        c.length AS comment_length,
        c.creator_person_id AS creator_id,
        CAST(NULL AS BIGINT) AS forum_id
    FROM comment_has_tag_tag cht
    JOIN comment c ON cht.comment_id = c.id
    JOIN tag t ON cht.tag_id = t.id
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
)
SELECT
    tag_class_id,
    tag_class_name,
    COUNT(DISTINCT post_id) AS post_count,
    COUNT(DISTINCT comment_id) AS comment_count,
    COUNT(DISTINCT creator_id) AS distinct_creator_count,
    COUNT(DISTINCT forum_id) AS forum_count,
    AVG(post_length) AS avg_post_length,
    AVG(comment_length) AS avg_comment_length
FROM unified_tags
GROUP BY tag_class_id, tag_class_name
ORDER BY post_count DESC
LIMIT 20
