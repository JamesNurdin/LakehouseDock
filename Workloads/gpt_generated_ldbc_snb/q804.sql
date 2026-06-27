/* Top tag class per forum based on the number of distinct tags associated with the forum */
WITH forum_tag_class_counts AS (
    SELECT
        f.id AS forum_id,
        f.title AS forum_title,
        tc.id AS tag_class_id,
        tc.name AS tag_class_name,
        COUNT(DISTINCT t.id) AS tag_count
    FROM forum f
    JOIN forum_has_tag_tag ft
        ON ft.forum_id = f.id
    JOIN tag t
        ON ft.tag_id = t.id
    JOIN tag_class tc
        ON t.type_tag_class_id = tc.id
    GROUP BY
        f.id,
        f.title,
        tc.id,
        tc.name
),
ranked_tag_classes AS (
    SELECT
        forum_id,
        forum_title,
        tag_class_id,
        tag_class_name,
        tag_count,
        RANK() OVER (PARTITION BY forum_id ORDER BY tag_count DESC) AS tag_class_rank
    FROM forum_tag_class_counts
)
SELECT
    forum_id,
    forum_title,
    tag_class_id,
    tag_class_name,
    tag_count
FROM ranked_tag_classes
WHERE tag_class_rank = 1
ORDER BY forum_id
