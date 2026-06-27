WITH forum_agg AS (
    SELECT
        tc.id AS tag_class_id,
        tc.name AS tag_class_name,
        pc.id AS parent_class_id,
        pc.name AS parent_class_name,
        COUNT(*) AS forum_tag_count,
        COUNT(DISTINCT fht.forum_id) AS distinct_forum_count,
        COUNT(DISTINCT t.id) AS distinct_tag_count
    FROM forum_has_tag_tag fht
    JOIN tag t ON fht.tag_id = t.id
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
    LEFT JOIN tag_class pc ON tc.subclass_of_tag_class_id = pc.id
    GROUP BY tc.id, tc.name, pc.id, pc.name
),
post_agg AS (
    SELECT
        tc.id AS tag_class_id,
        tc.name AS tag_class_name,
        pc.id AS parent_class_id,
        pc.name AS parent_class_name,
        COUNT(*) AS post_tag_count,
        COUNT(DISTINCT pht.post_id) AS distinct_post_count
    FROM post_has_tag_tag pht
    JOIN tag t ON pht.tag_id = t.id
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
    LEFT JOIN tag_class pc ON tc.subclass_of_tag_class_id = pc.id
    GROUP BY tc.id, tc.name, pc.id, pc.name
)
SELECT
    f.tag_class_id,
    f.tag_class_name,
    f.parent_class_id,
    f.parent_class_name,
    f.forum_tag_count,
    p.post_tag_count,
    f.distinct_forum_count,
    p.distinct_post_count,
    f.distinct_tag_count
FROM forum_agg f
LEFT JOIN post_agg p
    ON f.tag_class_id = p.tag_class_id
    AND (
        (f.parent_class_id = p.parent_class_id) OR (f.parent_class_id IS NULL AND p.parent_class_id IS NULL)
    )
ORDER BY f.forum_tag_count DESC
LIMIT 100
