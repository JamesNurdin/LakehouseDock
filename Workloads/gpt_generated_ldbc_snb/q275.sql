WITH forum_tag_class AS (
    SELECT
        f.id AS forum_id,
        tc.id AS tag_class_id,
        tc.name AS tag_class_name,
        parent_tc.id AS parent_tag_class_id,
        parent_tc.name AS parent_tag_class_name
    FROM forum_has_tag_tag fht
    JOIN forum f
        ON fht.forum_id = f.id
    JOIN tag t
        ON fht.tag_id = t.id
    JOIN tag_class tc
        ON t.type_tag_class_id = tc.id
    LEFT JOIN tag_class parent_tc
        ON tc.subclass_of_tag_class_id = parent_tc.id
),
total_forums AS (
    SELECT COUNT(*) AS total_forum_cnt FROM forum
),
aggregated AS (
    SELECT
        COALESCE(parent_tag_class_name, tag_class_name) AS root_tag_class_name,
        COUNT(DISTINCT forum_id) AS forum_count,
        COUNT(*) AS tag_assignment_count,
        COUNT(*) * 1.0 / COUNT(DISTINCT forum_id) AS avg_tags_per_forum
    FROM forum_tag_class
    GROUP BY COALESCE(parent_tag_class_name, tag_class_name)
)
SELECT
    a.root_tag_class_name,
    a.forum_count,
    a.tag_assignment_count,
    a.avg_tags_per_forum,
    a.forum_count * 100.0 / t.total_forum_cnt AS forum_percentage
FROM aggregated a
CROSS JOIN total_forums t
ORDER BY a.forum_count DESC
LIMIT 10
