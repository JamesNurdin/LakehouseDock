WITH base AS (
    SELECT
        c.id AS comment_id,
        c.parent_post_id,
        c.length AS comment_length
    FROM comment c
),
comments_tags AS (
    SELECT
        cht.comment_id,
        COUNT(DISTINCT cht.tag_id) AS tag_count
    FROM comment_has_tag_tag cht
    GROUP BY cht.comment_id
),
comments_likes AS (
    SELECT
        plc.comment_id,
        COUNT(DISTINCT plc.person_id) AS liker_count
    FROM person_likes_comment plc
    GROUP BY plc.comment_id
)
SELECT
    f.title AS forum_title,
    COUNT(b.comment_id) AS total_comments,
    SUM(b.comment_length) / NULLIF(COUNT(b.comment_id), 0) AS avg_comment_length,
    SUM(COALESCE(l.liker_count, 0)) AS total_comment_likes,
    SUM(COALESCE(t.tag_count, 0)) AS total_comment_tags
FROM base b
LEFT JOIN comments_tags t ON t.comment_id = b.comment_id
LEFT JOIN comments_likes l ON l.comment_id = b.comment_id
JOIN post p ON p.id = b.parent_post_id
JOIN forum f ON f.id = p.container_forum_id
GROUP BY f.title
ORDER BY total_comments DESC
LIMIT 5
