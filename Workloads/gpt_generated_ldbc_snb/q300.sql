WITH forum_tag_counts AS (
    SELECT
        tc.id AS tag_class_id,
        tc.name AS tag_class_name,
        COUNT(DISTINCT fht.forum_id) AS forum_count,
        COUNT(*) AS forum_tag_assignments
    FROM forum_has_tag_tag fht
    JOIN tag t ON fht.tag_id = t.id
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
    GROUP BY tc.id, tc.name
),
post_tag_counts AS (
    SELECT
        tc.id AS tag_class_id,
        tc.name AS tag_class_name,
        COUNT(DISTINCT pht.post_id) AS post_count,
        COUNT(*) AS post_tag_assignments
    FROM post_has_tag_tag pht
    JOIN tag t ON pht.tag_id = t.id
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
    GROUP BY tc.id, tc.name
),
combined AS (
    SELECT
        COALESCE(f.tag_class_id, p.tag_class_id) AS tag_class_id,
        COALESCE(f.tag_class_name, p.tag_class_name) AS tag_class_name,
        f.forum_count,
        f.forum_tag_assignments,
        p.post_count,
        p.post_tag_assignments
    FROM forum_tag_counts f
    FULL OUTER JOIN post_tag_counts p
        ON f.tag_class_id = p.tag_class_id
)
SELECT
    tag_class_id,
    tag_class_name,
    forum_count,
    post_count,
    forum_tag_assignments,
    post_tag_assignments,
    (forum_tag_assignments + post_tag_assignments) AS total_tag_assignments,
    CASE
        WHEN (forum_tag_assignments + post_tag_assignments) > 0 THEN
            (forum_tag_assignments * 100.0) / (forum_tag_assignments + post_tag_assignments)
        ELSE NULL
    END AS forum_assignment_pct
FROM combined
ORDER BY total_tag_assignments DESC
LIMIT 20
