WITH comment_tag AS (
    SELECT
        c.id AS comment_id,
        c.creator_person_id,
        c.length,
        c.parent_comment_id,
        t.id AS tag_id,
        t.name AS tag_name
    FROM comment c
    JOIN comment_has_tag_tag ct ON ct.comment_id = c.id
    JOIN tag t ON ct.tag_id = t.id
),
comment_reply_counts AS (
    SELECT
        cp.id AS parent_comment_id,
        COUNT(cc.id) AS reply_count
    FROM comment cp
    LEFT JOIN comment cc ON cc.parent_comment_id = cp.id
    GROUP BY cp.id
)
SELECT
    ct.tag_name,
    COUNT(DISTINCT ct.comment_id) AS comment_count,
    AVG(ct.length) AS avg_comment_length,
    COUNT(DISTINCT ct.creator_person_id) AS distinct_commenters,
    AVG(COALESCE(crc.reply_count, 0)) AS avg_replies_per_comment
FROM comment_tag ct
LEFT JOIN comment_reply_counts crc ON ct.comment_id = crc.parent_comment_id
GROUP BY ct.tag_name
ORDER BY comment_count DESC
LIMIT 10
