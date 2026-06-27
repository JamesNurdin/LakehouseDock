WITH forum_tag AS (
    SELECT
        f.id AS forum_id,
        f.creation_date AS forum_creation_date,
        t.id AS tag_id,
        t.name AS tag_name,
        t.type_tag_class_id,
        t.url
    FROM forum f
    JOIN forum_has_tag_tag fht
        ON fht.forum_id = f.id
    JOIN tag t
        ON fht.tag_id = t.id
)
SELECT
    tag_id,
    tag_name,
    type_tag_class_id,
    url,
    COUNT(DISTINCT forum_id) AS forum_count,
    MIN(forum_creation_date) AS earliest_forum_creation,
    MAX(forum_creation_date) AS latest_forum_creation
FROM forum_tag
GROUP BY tag_id, tag_name, type_tag_class_id, url
ORDER BY forum_count DESC
LIMIT 100
