WITH comment_base AS (
    SELECT
        c.id AS comment_id,
        c.length,
        c.creator_person_id
    FROM comment c
),
comment_likes AS (
    SELECT
        plc.comment_id,
        COUNT(*) AS like_count
    FROM person_likes_comment plc
    GROUP BY plc.comment_id
)
SELECT
    t.id AS tag_id,
    t.name AS tag_name,
    COUNT(DISTINCT cb.comment_id) AS total_comments,
    AVG(cb.length) AS avg_comment_length,
    SUM(COALESCE(cl.like_count, 0)) AS total_likes,
    COUNT(DISTINCT cb.creator_person_id) AS distinct_creators
FROM comment_has_tag_tag cht
JOIN comment_base cb
    ON cht.comment_id = cb.comment_id
LEFT JOIN comment_likes cl
    ON cb.comment_id = cl.comment_id
JOIN tag t
    ON cht.tag_id = t.id
GROUP BY t.id, t.name
ORDER BY total_comments DESC
LIMIT 10
