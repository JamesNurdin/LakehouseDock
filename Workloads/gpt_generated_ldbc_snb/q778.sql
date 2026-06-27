WITH all_likes AS (
    SELECT
        tc.id AS tag_class_id,
        tc.name AS tag_class_name,
        p.id AS item_id,
        'post' AS item_type,
        pl.person_id AS liker_id
    FROM post p
    JOIN post_has_tag_tag pht
        ON pht.post_id = p.id
    JOIN tag t
        ON t.id = pht.tag_id
    JOIN tag_class tc
        ON tc.id = t.type_tag_class_id
    JOIN person_likes_post pl
        ON pl.post_id = p.id

    UNION ALL

    SELECT
        tc.id AS tag_class_id,
        tc.name AS tag_class_name,
        c.id AS item_id,
        'comment' AS item_type,
        cl.person_id AS liker_id
    FROM comment c
    JOIN comment_has_tag_tag cht
        ON cht.comment_id = c.id
    JOIN tag t
        ON t.id = cht.tag_id
    JOIN tag_class tc
        ON tc.id = t.type_tag_class_id
    JOIN person_likes_comment cl
        ON cl.comment_id = c.id
)
SELECT
    tag_class_id,
    tag_class_name,
    COUNT(*) AS total_likes,
    COUNT(DISTINCT CASE WHEN item_type = 'post' THEN item_id END) AS total_posts,
    COUNT(DISTINCT CASE WHEN item_type = 'comment' THEN item_id END) AS total_comments
FROM all_likes
GROUP BY tag_class_id, tag_class_name
ORDER BY total_likes DESC
LIMIT 10
