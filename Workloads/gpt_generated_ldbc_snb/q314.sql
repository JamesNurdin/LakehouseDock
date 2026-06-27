WITH comment_tag AS (
    SELECT
        cht.tag_id,
        c.id AS comment_id,
        c.creator_person_id,
        c.length AS comment_length,
        c.location_country_id
    FROM comment_has_tag_tag cht
    JOIN comment c
        ON cht.comment_id = c.id
),
comment_with_replies AS (
    SELECT
        ct.tag_id,
        ct.comment_id,
        ct.creator_person_id,
        ct.comment_length,
        ct.location_country_id,
        r.id AS reply_id,
        r.length AS reply_length
    FROM comment_tag ct
    LEFT JOIN comment r
        ON r.parent_comment_id = ct.comment_id
)
SELECT
    cwr.tag_id,
    cwr.location_country_id,
    COUNT(DISTINCT cwr.comment_id) AS comment_count,
    COUNT(DISTINCT cwr.creator_person_id) AS distinct_creator_count,
    AVG(cwr.comment_length) AS avg_comment_length,
    COUNT(DISTINCT cwr.reply_id) AS reply_count,
    AVG(cwr.reply_length) AS avg_reply_length
FROM comment_with_replies cwr
GROUP BY cwr.tag_id, cwr.location_country_id
ORDER BY comment_count DESC
LIMIT 50
