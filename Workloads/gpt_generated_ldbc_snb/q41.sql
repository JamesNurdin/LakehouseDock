WITH comment_tag_stats AS (
    SELECT
        t.id AS tag_id,
        t.name AS tag_name,
        tc.name AS tag_class_name,
        COUNT(DISTINCT c.id) AS comment_count,
        COUNT(plc.person_id) AS comment_like_count,
        AVG(c.length) AS avg_comment_len
    FROM comment_has_tag_tag ctag
    JOIN comment c ON ctag.comment_id = c.id
    JOIN tag t ON ctag.tag_id = t.id
    LEFT JOIN tag_class tc ON t.type_tag_class_id = tc.id
    LEFT JOIN person_likes_comment plc ON plc.comment_id = c.id
    GROUP BY t.id, t.name, tc.name
),
post_tag_stats AS (
    SELECT
        t.id AS tag_id,
        t.name AS tag_name,
        tc.name AS tag_class_name,
        COUNT(DISTINCT p.id) AS post_count,
        COUNT(plp.person_id) AS post_like_count,
        AVG(p.length) AS avg_post_len
    FROM post_has_tag_tag ptag
    JOIN post p ON ptag.post_id = p.id
    JOIN tag t ON ptag.tag_id = t.id
    LEFT JOIN tag_class tc ON t.type_tag_class_id = tc.id
    LEFT JOIN person_likes_post plp ON plp.post_id = p.id
    GROUP BY t.id, t.name, tc.name
)
SELECT
    COALESCE(ct.tag_id, pt.tag_id) AS tag_id,
    COALESCE(ct.tag_name, pt.tag_name) AS tag_name,
    COALESCE(ct.tag_class_name, pt.tag_class_name) AS tag_class_name,
    COALESCE(ct.comment_count, 0) AS comment_count,
    COALESCE(pt.post_count, 0) AS post_count,
    COALESCE(ct.comment_like_count, 0) AS comment_like_count,
    COALESCE(pt.post_like_count, 0) AS post_like_count,
    COALESCE(ct.avg_comment_len, 0) AS avg_comment_len,
    COALESCE(pt.avg_post_len, 0) AS avg_post_len,
    (COALESCE(ct.comment_count, 0) + COALESCE(pt.post_count, 0)) AS total_items,
    (COALESCE(ct.comment_like_count, 0) + COALESCE(pt.post_like_count, 0)) AS total_likes
FROM comment_tag_stats ct
FULL OUTER JOIN post_tag_stats pt ON ct.tag_id = pt.tag_id
ORDER BY total_items DESC, total_likes DESC
LIMIT 100
