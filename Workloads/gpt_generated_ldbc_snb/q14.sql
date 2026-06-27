WITH comment_tag_info AS (
    SELECT
        c.id AS comment_id,
        c.length AS comment_length,
        f.title AS forum_title,
        tc.name AS tag_class_name
    FROM comment c
    JOIN post po
        ON c.parent_post_id = po.id
    JOIN forum f
        ON po.container_forum_id = f.id
    JOIN person p
        ON f.moderator_person_id = p.id
    JOIN comment_has_tag_tag cht
        ON cht.comment_id = c.id
    JOIN tag t
        ON cht.tag_id = t.id
    JOIN tag_class tc
        ON t.type_tag_class_id = tc.id
    WHERE p.gender = 'male'
)
SELECT
    forum_title,
    tag_class_name,
    COUNT(comment_id) AS comment_count,
    SUM(comment_length) AS total_comment_length,
    AVG(comment_length) AS avg_comment_length
FROM comment_tag_info
GROUP BY forum_title, tag_class_name
ORDER BY comment_count DESC
LIMIT 10
