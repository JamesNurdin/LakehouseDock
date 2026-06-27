WITH comment_metrics AS (
    SELECT
        c.id AS comment_id,
        c.length AS comment_length,
        c.creator_person_id,
        COUNT(plc.person_id) AS like_count
    FROM comment c
    LEFT JOIN person_likes_comment plc
        ON plc.comment_id = c.id
    GROUP BY c.id, c.length, c.creator_person_id
),
comment_tag_class AS (
    SELECT DISTINCT
        tc.id AS tag_class_id,
        tc.name AS tag_class_name,
        cm.comment_id,
        cm.comment_length,
        cm.like_count,
        cm.creator_person_id
    FROM comment_metrics cm
    JOIN comment_has_tag_tag cht
        ON cht.comment_id = cm.comment_id
    JOIN tag t
        ON t.id = cht.tag_id
    JOIN tag_class tc
        ON tc.id = t.type_tag_class_id
)
SELECT
    ctc.tag_class_id,
    ctc.tag_class_name,
    COUNT(ctc.comment_id) AS comment_count,
    AVG(ctc.comment_length) AS avg_comment_length,
    SUM(ctc.like_count) AS total_likes,
    COUNT(DISTINCT ctc.creator_person_id) AS distinct_creators
FROM comment_tag_class ctc
GROUP BY ctc.tag_class_id, ctc.tag_class_name
ORDER BY total_likes DESC
LIMIT 10
