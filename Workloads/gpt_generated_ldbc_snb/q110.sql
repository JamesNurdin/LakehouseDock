WITH post_metrics AS (
    SELECT
        tc.id AS tag_class_id,
        p.id AS post_id,
        p.length AS post_length
    FROM post_has_tag_tag pht
    JOIN post p ON pht.post_id = p.id
    JOIN tag t ON pht.tag_id = t.id
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
),
comment_metrics AS (
    SELECT
        tc.id AS tag_class_id,
        cht.comment_id AS comment_id
    FROM comment_has_tag_tag cht
    JOIN tag t ON cht.tag_id = t.id
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
),
person_metrics AS (
    SELECT
        tc.id AS tag_class_id,
        phi.person_id AS person_id
    FROM person_has_interest_tag phi
    JOIN tag t ON phi.tag_id = t.id
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
),
tag_class_hierarchy AS (
    SELECT
        tc.id AS tag_class_id,
        COALESCE(parent_tc.id, tc.id) AS root_tag_class_id,
        COALESCE(parent_tc.name, tc.name) AS root_tag_class_name,
        tc.name AS tag_class_name
    FROM tag_class tc
    LEFT JOIN tag_class parent_tc ON tc.subclass_of_tag_class_id = parent_tc.id
)
SELECT
    h.root_tag_class_name,
    COUNT(DISTINCT pm.post_id) AS post_count,
    AVG(pm.post_length) AS avg_post_length,
    COUNT(DISTINCT cm.comment_id) AS comment_count,
    COUNT(DISTINCT per.person_id) AS person_interest_count
FROM tag_class_hierarchy h
LEFT JOIN post_metrics pm ON pm.tag_class_id = h.tag_class_id
LEFT JOIN comment_metrics cm ON cm.tag_class_id = h.tag_class_id
LEFT JOIN person_metrics per ON per.tag_class_id = h.tag_class_id
GROUP BY h.root_tag_class_name
ORDER BY post_count DESC
LIMIT 10
