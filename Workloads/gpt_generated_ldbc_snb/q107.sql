WITH post_metrics AS (
    SELECT
        tc.id AS tag_class_id,
        tc.name AS tag_class_name,
        COUNT(DISTINCT p.id) AS post_count,
        AVG(p.length) AS avg_post_length,
        COUNT(pl.person_id) AS total_likes
    FROM post p
    JOIN post_has_tag_tag pht ON pht.post_id = p.id
    JOIN tag t ON pht.tag_id = t.id
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
    LEFT JOIN person_likes_post pl ON pl.post_id = p.id
    GROUP BY tc.id, tc.name
),
comment_metrics AS (
    SELECT
        tc.id AS tag_class_id,
        tc.name AS tag_class_name,
        COUNT(DISTINCT c.id) AS comment_count,
        AVG(c.length) AS avg_comment_length
    FROM comment c
    JOIN comment_has_tag_tag cht ON cht.comment_id = c.id
    JOIN tag t ON cht.tag_id = t.id
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
    GROUP BY tc.id, tc.name
)
SELECT
    pm.tag_class_name,
    pm.post_count,
    pm.avg_post_length,
    pm.total_likes,
    cm.comment_count,
    cm.avg_comment_length
FROM post_metrics pm
LEFT JOIN comment_metrics cm ON pm.tag_class_id = cm.tag_class_id
ORDER BY pm.post_count DESC
LIMIT 20
