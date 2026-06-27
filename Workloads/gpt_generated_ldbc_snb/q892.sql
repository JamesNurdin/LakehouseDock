WITH comment_tag_likes AS (
    SELECT
        c.id AS comment_id,
        c.length AS comment_length,
        t.id AS tag_id,
        t.name AS tag_name,
        tc.id AS tag_class_id,
        tc.name AS tag_class_name,
        plc.person_id AS liker_person_id
    FROM comment AS c
    JOIN comment_has_tag_tag AS cht
        ON cht.comment_id = c.id
    JOIN tag AS t
        ON cht.tag_id = t.id
    JOIN tag_class AS tc
        ON t.type_tag_class_id = tc.id
    JOIN person_likes_comment AS plc
        ON plc.comment_id = c.id
)
SELECT
    tag_class_name,
    COUNT(*) AS total_likes,
    COUNT(DISTINCT liker_person_id) AS distinct_likers,
    COUNT(DISTINCT comment_id) AS distinct_comments,
    AVG(comment_length) AS avg_comment_length
FROM comment_tag_likes
GROUP BY tag_class_name
ORDER BY total_likes DESC
LIMIT 10
