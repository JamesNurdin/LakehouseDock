WITH post_metrics AS (
    SELECT
        tc.id AS tag_class_id,
        tc.name AS tag_class_name,
        ptc.id AS parent_tag_class_id,
        ptc.name AS parent_tag_class_name,
        COUNT(DISTINCT p.id) AS post_count,
        AVG(p.length) AS avg_post_length
    FROM post_has_tag_tag pht
    JOIN post p
        ON pht.post_id = p.id
    JOIN tag t
        ON pht.tag_id = t.id
    JOIN tag_class tc
        ON t.type_tag_class_id = tc.id
    LEFT JOIN tag_class ptc
        ON tc.subclass_of_tag_class_id = ptc.id
    GROUP BY
        tc.id,
        tc.name,
        ptc.id,
        ptc.name
),
comment_metrics AS (
    SELECT
        tc.id AS tag_class_id,
        tc.name AS tag_class_name,
        ptc.id AS parent_tag_class_id,
        ptc.name AS parent_tag_class_name,
        COUNT(DISTINCT cht.comment_id) AS comment_count
    FROM comment_has_tag_tag cht
    JOIN tag t
        ON cht.tag_id = t.id
    JOIN tag_class tc
        ON t.type_tag_class_id = tc.id
    LEFT JOIN tag_class ptc
        ON tc.subclass_of_tag_class_id = ptc.id
    GROUP BY
        tc.id,
        tc.name,
        ptc.id,
        ptc.name
)
SELECT
    COALESCE(pm.parent_tag_class_name, cm.parent_tag_class_name) AS parent_tag_class_name,
    COALESCE(pm.tag_class_name, cm.tag_class_name) AS tag_class_name,
    COALESCE(pm.post_count, 0) AS post_count,
    COALESCE(cm.comment_count, 0) AS comment_count,
    pm.avg_post_length
FROM post_metrics pm
FULL OUTER JOIN comment_metrics cm
    ON pm.tag_class_id = cm.tag_class_id
ORDER BY
    parent_tag_class_name,
    tag_class_name
