WITH comment_with_replies AS (
    SELECT
        c.id AS comment_id,
        c.parent_post_id,
        c.creator_person_id,
        c.length,
        COUNT(r.id) AS reply_count
    FROM comment c
    LEFT JOIN comment r
        ON r.parent_comment_id = c.id
    GROUP BY
        c.id,
        c.parent_post_id,
        c.creator_person_id,
        c.length
)
SELECT
    p.id AS post_id,
    p.language,
    COUNT(cwr.comment_id) AS total_comments,
    AVG(cwr.length) AS avg_comment_length,
    AVG(cwr.reply_count) AS avg_replies_per_comment,
    COUNT(DISTINCT cwr.creator_person_id) AS distinct_commenters
FROM post p
JOIN comment_with_replies cwr
    ON cwr.parent_post_id = p.id
GROUP BY
    p.id,
    p.language
ORDER BY total_comments DESC
LIMIT 10
