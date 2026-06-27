WITH comment_reply AS (
    SELECT
        parent.id AS comment_id,
        parent.length,
        parent.creator_person_id,
        parent.creation_date,
        COUNT(child.id) AS reply_count
    FROM comment AS parent
    LEFT JOIN comment AS child
        ON child.parent_comment_id = parent.id
    GROUP BY parent.id, parent.length, parent.creator_person_id, parent.creation_date
)
SELECT
    tag.id AS tag_id,
    tag.name AS tag_name,
    tag.type_tag_class_id,
    COUNT(DISTINCT cr.comment_id) AS total_comments,
    AVG(cr.length) AS avg_comment_length,
    AVG(cr.reply_count) AS avg_replies_per_comment,
    COUNT(DISTINCT cr.creator_person_id) AS distinct_creators,
    MIN(cr.creation_date) AS earliest_comment_date,
    MAX(cr.creation_date) AS latest_comment_date
FROM comment_reply AS cr
JOIN comment_has_tag_tag AS cht
    ON cht.comment_id = cr.comment_id
JOIN tag
    ON tag.id = cht.tag_id
GROUP BY tag.id, tag.name, tag.type_tag_class_id
ORDER BY total_comments DESC
LIMIT 10
