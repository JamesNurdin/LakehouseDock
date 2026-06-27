WITH likes_per_comment AS (
    SELECT
        comment_id,
        COUNT(person_id) AS like_count
    FROM person_likes_comment
    GROUP BY comment_id
),
replies_per_comment AS (
    SELECT
        parent_comment_id AS comment_id,
        COUNT(*) AS reply_count
    FROM comment
    WHERE parent_comment_id IS NOT NULL
    GROUP BY parent_comment_id
),
comment_tag_class AS (
    SELECT DISTINCT
        c.id AS comment_id,
        c.creator_person_id,
        c.length,
        c.location_country_id,
        COALESCE(parent_tc.name, tc.name) AS parent_tag_class_name,
        COALESCE(lc.like_count, 0) AS like_count,
        COALESCE(rc.reply_count, 0) AS reply_count
    FROM comment c
    JOIN comment_has_tag_tag cht
        ON cht.comment_id = c.id
    JOIN tag t
        ON t.id = cht.tag_id
    JOIN tag_class tc
        ON tc.id = t.type_tag_class_id
    LEFT JOIN tag_class parent_tc
        ON parent_tc.id = tc.subclass_of_tag_class_id
    LEFT JOIN likes_per_comment lc
        ON lc.comment_id = c.id
    LEFT JOIN replies_per_comment rc
        ON rc.comment_id = c.id
)
SELECT
    ctc.parent_tag_class_name,
    p.name AS country_name,
    COUNT(DISTINCT ctc.comment_id) AS total_comments,
    SUM(ctc.like_count) AS total_likes,
    AVG(ctc.length) AS avg_comment_length,
    SUM(ctc.reply_count) AS total_replies,
    COUNT(DISTINCT ctc.creator_person_id) AS distinct_commenters
FROM comment_tag_class ctc
JOIN place p
    ON p.id = ctc.location_country_id
GROUP BY ctc.parent_tag_class_name, p.name
ORDER BY total_comments DESC
LIMIT 20
