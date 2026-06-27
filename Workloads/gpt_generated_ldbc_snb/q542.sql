WITH post_tag AS (
    SELECT
        pht.post_id,
        t.id AS tag_id,
        t.name AS tag_name,
        t.type_tag_class_id,
        tc.id AS tag_class_id,
        tc.name AS tag_class_name,
        tc.subclass_of_tag_class_id,
        parent_tc.id AS parent_tag_class_id,
        parent_tc.name AS parent_tag_class_name
    FROM post_has_tag_tag AS pht
    JOIN tag AS t ON pht.tag_id = t.id
    JOIN tag_class AS tc ON t.type_tag_class_id = tc.id
    LEFT JOIN tag_class AS parent_tc ON tc.subclass_of_tag_class_id = parent_tc.id
),
post_tag_class_counts AS (
    SELECT
        post_id,
        COALESCE(parent_tag_class_name, tag_class_name) AS top_tag_class_name,
        COUNT(*) AS tags_in_top_class
    FROM post_tag
    GROUP BY post_id, COALESCE(parent_tag_class_name, tag_class_name)
)
SELECT
    top_tag_class_name,
    COUNT(DISTINCT post_id) AS distinct_post_count,
    SUM(tags_in_top_class) AS total_tag_assignments,
    AVG(tags_in_top_class) AS avg_tags_per_post
FROM post_tag_class_counts
GROUP BY top_tag_class_name
ORDER BY distinct_post_count DESC
LIMIT 20
