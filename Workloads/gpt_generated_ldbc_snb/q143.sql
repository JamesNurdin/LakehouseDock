WITH post_metrics AS (
    SELECT
        tc.id AS tag_class_id,
        COUNT(DISTINCT p.id) AS post_count,
        AVG(p.length) AS avg_post_length
    FROM post_has_tag_tag pht
    JOIN post p
        ON pht.post_id = p.id
    JOIN tag t
        ON pht.tag_id = t.id
    JOIN tag_class tc
        ON t.type_tag_class_id = tc.id
    GROUP BY tc.id
),
comment_metrics AS (
    SELECT
        tc.id AS tag_class_id,
        COUNT(DISTINCT c.id) AS comment_count,
        AVG(c.length) AS avg_comment_length
    FROM comment_has_tag_tag cht
    JOIN comment c
        ON cht.comment_id = c.id
    JOIN tag t
        ON cht.tag_id = t.id
    JOIN tag_class tc
        ON t.type_tag_class_id = tc.id
    GROUP BY tc.id
),
person_interest_metrics AS (
    SELECT
        tc.id AS tag_class_id,
        COUNT(DISTINCT pit.person_id) AS interested_person_count
    FROM person_has_interest_tag pit
    JOIN tag t
        ON pit.tag_id = t.id
    JOIN tag_class tc
        ON t.type_tag_class_id = tc.id
    GROUP BY tc.id
)
SELECT
    tc.id AS tag_class_id,
    tc.name AS tag_class_name,
    parent_tc.name AS parent_tag_class_name,
    COALESCE(pm.post_count, 0) AS post_count,
    COALESCE(cm.comment_count, 0) AS comment_count,
    COALESCE(pim.interested_person_count, 0) AS interested_person_count,
    pm.avg_post_length,
    cm.avg_comment_length
FROM tag_class tc
LEFT JOIN tag_class parent_tc
    ON tc.subclass_of_tag_class_id = parent_tc.id
LEFT JOIN post_metrics pm
    ON pm.tag_class_id = tc.id
LEFT JOIN comment_metrics cm
    ON cm.tag_class_id = tc.id
LEFT JOIN person_interest_metrics pim
    ON pim.tag_class_id = tc.id
ORDER BY post_count DESC
LIMIT 10
