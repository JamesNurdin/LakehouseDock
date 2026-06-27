WITH post_metrics AS (
    SELECT
        tc.id AS tag_class_id,
        tc.name AS tag_class_name,
        COUNT(DISTINCT p.id) AS post_count,
        AVG(p.length) AS avg_post_length
    FROM
        tag_class tc
    JOIN tag t
        ON t.type_tag_class_id = tc.id
    JOIN post_has_tag_tag pht
        ON pht.tag_id = t.id
    JOIN post p
        ON p.id = pht.post_id
    GROUP BY
        tc.id,
        tc.name
),
comment_metrics AS (
    SELECT
        tc.id AS tag_class_id,
        tc.name AS tag_class_name,
        COUNT(DISTINCT c.id) AS comment_count,
        AVG(c.length) AS avg_comment_length
    FROM
        tag_class tc
    JOIN tag t
        ON t.type_tag_class_id = tc.id
    JOIN comment_has_tag_tag cht
        ON cht.tag_id = t.id
    JOIN comment c
        ON c.id = cht.comment_id
    GROUP BY
        tc.id,
        tc.name
)
SELECT
    COALESCE(pm.tag_class_id, cm.tag_class_id) AS tag_class_id,
    COALESCE(pm.tag_class_name, cm.tag_class_name) AS tag_class_name,
    pm.post_count,
    pm.avg_post_length,
    cm.comment_count,
    cm.avg_comment_length
FROM
    post_metrics pm
FULL OUTER JOIN comment_metrics cm
    ON pm.tag_class_id = cm.tag_class_id
ORDER BY
    tag_class_name
LIMIT 20
