WITH all_likes AS (
    -- Likes on posts together with the tags of those posts
    SELECT
        tc.id AS tag_class_id,
        tc.name AS tag_class_name,
        pl.person_id AS liker_id,
        p.length AS post_length,
        CAST(NULL AS integer) AS comment_length,
        t.id AS tag_id
    FROM post_has_tag_tag pht
    JOIN post p ON pht.post_id = p.id
    JOIN tag t ON pht.tag_id = t.id
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
    JOIN person_likes_post pl ON pl.post_id = p.id

    UNION ALL

    -- Likes on comments together with the tags of those comments
    SELECT
        tc.id,
        tc.name,
        cl.person_id,
        CAST(NULL AS integer),
        c.length,
        t.id
    FROM comment_has_tag_tag cht
    JOIN comment c ON cht.comment_id = c.id
    JOIN tag t ON cht.tag_id = t.id
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
    JOIN person_likes_comment cl ON cl.comment_id = c.id
)
SELECT
    tag_class_id,
    tag_class_name,
    COUNT(liker_id) AS total_likes,
    AVG(post_length) AS avg_post_length,
    AVG(comment_length) AS avg_comment_length,
    COUNT(DISTINCT tag_id) AS distinct_tags
FROM all_likes
GROUP BY tag_class_id, tag_class_name
ORDER BY total_likes DESC
LIMIT 20
