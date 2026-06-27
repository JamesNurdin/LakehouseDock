WITH combined AS (
    -- Posts with their tags and like counts
    SELECT
        t.id AS tag_id,
        t.name AS tag_name,
        'post' AS item_type,
        p.id AS item_id,
        p.length AS item_length,
        COUNT(plp.person_id) AS like_cnt
    FROM post_has_tag_tag p_ht
    JOIN post p ON p_ht.post_id = p.id
    JOIN tag t ON p_ht.tag_id = t.id
    LEFT JOIN person_likes_post plp ON plp.post_id = p.id
    GROUP BY t.id, t.name, p.id, p.length

    UNION ALL

    -- Comments with their tags and like counts
    SELECT
        t.id AS tag_id,
        t.name AS tag_name,
        'comment' AS item_type,
        c.id AS item_id,
        c.length AS item_length,
        COUNT(plc.person_id) AS like_cnt
    FROM comment_has_tag_tag c_ht
    JOIN comment c ON c_ht.comment_id = c.id
    JOIN tag t ON c_ht.tag_id = t.id
    LEFT JOIN person_likes_comment plc ON plc.comment_id = c.id
    GROUP BY t.id, t.name, c.id, c.length
)
SELECT
    tag_id,
    tag_name,
    SUM(CASE WHEN item_type = 'post'    THEN 1 ELSE 0 END) AS post_count,
    SUM(CASE WHEN item_type = 'comment' THEN 1 ELSE 0 END) AS comment_count,
    SUM(like_cnt) AS total_like_count,
    SUM(CASE WHEN item_type = 'post'    THEN item_length ELSE 0 END) / NULLIF(SUM(CASE WHEN item_type = 'post'    THEN 1 ELSE 0 END), 0) AS avg_post_length,
    SUM(CASE WHEN item_type = 'comment' THEN item_length ELSE 0 END) / NULLIF(SUM(CASE WHEN item_type = 'comment' THEN 1 ELSE 0 END), 0) AS avg_comment_length
FROM combined
GROUP BY tag_id, tag_name
ORDER BY total_like_count DESC
LIMIT 10
