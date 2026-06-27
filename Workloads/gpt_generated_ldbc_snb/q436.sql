WITH tag_class_hierarchy AS (
    SELECT
        c.id AS tag_class_id,
        c.name AS tag_class_name,
        pc.id AS parent_class_id,
        pc.name AS parent_class_name
    FROM tag_class c
    LEFT JOIN tag_class pc
        ON c.subclass_of_tag_class_id = pc.id
),

tag_class_metrics AS (
    SELECT
        tag_class.id AS tag_class_id,
        tag_class.name AS tag_class_name,
        tag_class_hierarchy.parent_class_name,
        COUNT(DISTINCT person_has_interest_tag.person_id) AS distinct_persons,
        COUNT(person_has_interest_tag.tag_id) AS interest_events,
        COUNT(DISTINCT tag.id) AS distinct_tags,
        (COUNT(DISTINCT person_has_interest_tag.person_id) * 1.0) / NULLIF(COUNT(DISTINCT tag.id), 0) AS persons_per_tag
    FROM person_has_interest_tag
    JOIN tag
        ON person_has_interest_tag.tag_id = tag.id
    JOIN tag_class
        ON tag.type_tag_class_id = tag_class.id
    LEFT JOIN tag_class_hierarchy
        ON tag_class.id = tag_class_hierarchy.tag_class_id
    GROUP BY
        tag_class.id,
        tag_class.name,
        tag_class_hierarchy.parent_class_name
)
SELECT
    tag_class_name,
    COALESCE(parent_class_name, 'Root') AS parent_class_name,
    distinct_persons,
    interest_events,
    distinct_tags,
    persons_per_tag,
    ROW_NUMBER() OVER (
        PARTITION BY COALESCE(parent_class_name, 'Root')
        ORDER BY distinct_persons DESC
    ) AS rank_within_parent
FROM tag_class_metrics
ORDER BY distinct_persons DESC
LIMIT 10
