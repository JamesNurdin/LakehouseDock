WITH post_tag_class AS (
    SELECT
        p.id AS post_id,
        p.length AS post_length,
        p.creator_person_id AS creator_person_id,
        t.id AS tag_id,
        t.name AS tag_name,
        tc.id AS tag_class_id,
        tc.name AS tag_class_name
    FROM post p
    JOIN post_has_tag_tag pt ON p.id = pt.post_id
    JOIN tag t ON pt.tag_id = t.id
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
),
comment_tag_class AS (
    SELECT
        c.id AS comment_id,
        c.length AS comment_length,
        c.creator_person_id AS creator_person_id,
        t.id AS tag_id,
        t.name AS tag_name,
        tc.id AS tag_class_id,
        tc.name AS tag_class_name
    FROM comment c
    JOIN comment_has_tag_tag ct ON c.id = ct.comment_id
    JOIN tag t ON ct.tag_id = t.id
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
),
combined AS (
    SELECT
        tag_class_id,
        tag_class_name,
        'post' AS entity_type,
        post_id AS entity_id,
        post_length AS entity_length,
        creator_person_id
    FROM post_tag_class
    UNION ALL
    SELECT
        tag_class_id,
        tag_class_name,
        'comment' AS entity_type,
        comment_id AS entity_id,
        comment_length AS entity_length,
        creator_person_id
    FROM comment_tag_class
)
SELECT
    tag_class_name,
    COUNT(DISTINCT CASE WHEN entity_type = 'post' THEN entity_id END) AS post_count,
    COUNT(DISTINCT CASE WHEN entity_type = 'comment' THEN entity_id END) AS comment_count,
    AVG(CASE WHEN entity_type = 'post' THEN entity_length END) AS avg_post_length,
    AVG(CASE WHEN entity_type = 'comment' THEN entity_length END) AS avg_comment_length,
    COUNT(DISTINCT creator_person_id) AS distinct_contributors
FROM combined
GROUP BY tag_class_name
ORDER BY post_count DESC, comment_count DESC
