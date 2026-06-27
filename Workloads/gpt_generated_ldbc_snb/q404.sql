WITH comment_usage AS (
    SELECT
        t.type_tag_class_id AS tag_class_id,
        1 AS usage_cnt
    FROM comment_has_tag_tag c
    JOIN tag t ON c.tag_id = t.id
),
forum_usage AS (
    SELECT
        t.type_tag_class_id AS tag_class_id,
        1 AS usage_cnt
    FROM forum_has_tag_tag f
    JOIN tag t ON f.tag_id = t.id
),
post_usage AS (
    SELECT
        t.type_tag_class_id AS tag_class_id,
        1 AS usage_cnt
    FROM post_has_tag_tag p
    JOIN tag t ON p.tag_id = t.id
),
person_usage AS (
    SELECT
        t.type_tag_class_id AS tag_class_id,
        1 AS usage_cnt
    FROM person_has_interest_tag p
    JOIN tag t ON p.tag_id = t.id
),
combined_usage AS (
    SELECT tag_class_id, usage_cnt FROM comment_usage
    UNION ALL
    SELECT tag_class_id, usage_cnt FROM forum_usage
    UNION ALL
    SELECT tag_class_id, usage_cnt FROM post_usage
    UNION ALL
    SELECT tag_class_id, usage_cnt FROM person_usage
)
SELECT
    tc.name AS tag_class_name,
    parent_tc.name AS parent_class_name,
    COUNT(*) AS total_usages
FROM combined_usage cu
JOIN tag_class tc ON cu.tag_class_id = tc.id
LEFT JOIN tag_class parent_tc ON tc.subclass_of_tag_class_id = parent_tc.id
GROUP BY tc.name, parent_tc.name
ORDER BY total_usages DESC
LIMIT 10
