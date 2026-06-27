WITH forum_tag_counts AS (
    SELECT
        fht.forum_id,
        t.type_tag_class_id,
        COUNT(*) AS tag_assignments,
        COUNT(DISTINCT t.id) AS distinct_tags,
        MIN(fht.creation_date) AS first_tag_date,
        MAX(fht.creation_date) AS last_tag_date
    FROM forum_has_tag_tag AS fht
    JOIN tag AS t
        ON fht.tag_id = t.id
    GROUP BY fht.forum_id, t.type_tag_class_id
),
ranked_forums AS (
    SELECT
        forum_id,
        type_tag_class_id,
        tag_assignments,
        distinct_tags,
        first_tag_date,
        last_tag_date,
        ROW_NUMBER() OVER (PARTITION BY forum_id ORDER BY tag_assignments DESC) AS rn
    FROM forum_tag_counts
)
SELECT
    forum_id,
    type_tag_class_id,
    tag_assignments,
    distinct_tags,
    first_tag_date,
    last_tag_date
FROM ranked_forums
WHERE rn = 1
ORDER BY tag_assignments DESC
LIMIT 50
