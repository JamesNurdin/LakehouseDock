WITH post_likes AS (
    SELECT
        tag.id AS tag_id,
        tag.name AS tag_name,
        tag_class.name AS tag_class_name,
        COUNT(*) AS likes_count
    FROM person_likes_post AS plp
    JOIN post ON plp.post_id = post.id
    JOIN post_has_tag_tag AS pht ON post.id = pht.post_id
    JOIN tag ON pht.tag_id = tag.id
    JOIN tag_class ON tag.type_tag_class_id = tag_class.id
    GROUP BY tag.id, tag.name, tag_class.name
),
comment_likes AS (
    SELECT
        tag.id AS tag_id,
        tag.name AS tag_name,
        tag_class.name AS tag_class_name,
        COUNT(*) AS likes_count
    FROM person_likes_comment AS plc
    JOIN comment ON plc.comment_id = comment.id
    JOIN comment_has_tag_tag AS cht ON comment.id = cht.comment_id
    JOIN tag ON cht.tag_id = tag.id
    JOIN tag_class ON tag.type_tag_class_id = tag_class.id
    GROUP BY tag.id, tag.name, tag_class.name
),
combined AS (
    SELECT tag_id, tag_name, tag_class_name, likes_count FROM post_likes
    UNION ALL
    SELECT tag_id, tag_name, tag_class_name, likes_count FROM comment_likes
)
SELECT
    tag_id,
    tag_name,
    tag_class_name,
    SUM(likes_count) AS total_likes
FROM combined
GROUP BY tag_id, tag_name, tag_class_name
ORDER BY total_likes DESC
LIMIT 10
