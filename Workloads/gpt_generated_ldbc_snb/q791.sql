WITH comment_tag_stats AS (
    SELECT
        t.id AS tag_id,
        t.name AS tag_name,
        COUNT(*) AS comment_count,
        COUNT(DISTINCT plc.person_id) AS like_count,
        AVG(c.length) AS avg_comment_length,
        COUNT(DISTINCT f.id) AS forum_count
    FROM comment c
    JOIN comment_has_tag_tag ctag ON ctag.comment_id = c.id
    JOIN tag t ON t.id = ctag.tag_id
    LEFT JOIN person_likes_comment plc ON plc.comment_id = c.id
    LEFT JOIN post p ON p.id = c.parent_post_id
    LEFT JOIN forum f ON f.id = p.container_forum_id
    GROUP BY t.id, t.name
)
SELECT
    tag_id,
    tag_name,
    comment_count,
    like_count,
    avg_comment_length,
    forum_count
FROM comment_tag_stats
ORDER BY like_count DESC, comment_count DESC
LIMIT 10
