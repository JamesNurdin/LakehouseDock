WITH comment_tag AS (
    SELECT
        c.id AS comment_id,
        c.length,
        c.creator_person_id,
        c.parent_comment_id,
        ct.tag_id
    FROM comment c
    JOIN comment_has_tag_tag ct
        ON ct.comment_id = c.id
),
comment_likes AS (
    SELECT
        plc.comment_id,
        COUNT(*) AS like_count
    FROM person_likes_comment plc
    GROUP BY plc.comment_id
),
comment_replies AS (
    SELECT
        p.id AS comment_id,
        COUNT(c.id) AS reply_count
    FROM comment c
    JOIN comment p
        ON c.parent_comment_id = p.id
    GROUP BY p.id
)
SELECT
    t.id AS tag_id,
    t.name AS tag_name,
    COUNT(DISTINCT ct.comment_id) AS comment_count,
    COALESCE(SUM(l.like_count), 0) AS total_likes,
    AVG(ct.length) AS avg_comment_length,
    COUNT(DISTINCT ct.creator_person_id) AS distinct_creators,
    AVG(COALESCE(r.reply_count, 0)) AS avg_replies_per_comment
FROM tag t
JOIN comment_tag ct
    ON ct.tag_id = t.id
LEFT JOIN comment_likes l
    ON ct.comment_id = l.comment_id
LEFT JOIN comment_replies r
    ON ct.comment_id = r.comment_id
GROUP BY t.id, t.name
ORDER BY total_likes DESC
LIMIT 10
