/*
  Analytical query: top tag classes by total tag assignments in forums and posts.
  Joins:
    forum_has_tag_tag.tag_id = tag.id
    post_has_tag_tag.tag_id = tag.id
    tag.type_tag_class_id = tag_class.id
    tag_class.subclass_of_tag_class_id = parent_tag_class.id
*/
WITH forum_usage AS (
    SELECT
        tc.id AS tag_class_id,
        ptc.id AS parent_tag_class_id,
        tc.name AS tag_class_name,
        ptc.name AS parent_tag_class_name,
        COUNT(*) AS forum_tag_count,
        COUNT(DISTINCT t.id) AS distinct_tag_count_forum
    FROM forum_has_tag_tag fht
    JOIN tag t ON fht.tag_id = t.id
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
    LEFT JOIN tag_class ptc ON tc.subclass_of_tag_class_id = ptc.id
    GROUP BY
        tc.id,
        ptc.id,
        tc.name,
        ptc.name
),
post_usage AS (
    SELECT
        tc.id AS tag_class_id,
        ptc.id AS parent_tag_class_id,
        tc.name AS tag_class_name,
        ptc.name AS parent_tag_class_name,
        COUNT(*) AS post_tag_count,
        COUNT(DISTINCT t.id) AS distinct_tag_count_post
    FROM post_has_tag_tag pht
    JOIN tag t ON pht.tag_id = t.id
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
    LEFT JOIN tag_class ptc ON tc.subclass_of_tag_class_id = ptc.id
    GROUP BY
        tc.id,
        ptc.id,
        tc.name,
        ptc.name
)
SELECT
    COALESCE(f.tag_class_id, p.tag_class_id) AS tag_class_id,
    COALESCE(f.parent_tag_class_id, p.parent_tag_class_id) AS parent_tag_class_id,
    COALESCE(f.tag_class_name, p.tag_class_name) AS tag_class_name,
    COALESCE(f.parent_tag_class_name, p.parent_tag_class_name) AS parent_tag_class_name,
    COALESCE(f.forum_tag_count, 0) AS forum_tag_count,
    COALESCE(p.post_tag_count, 0) AS post_tag_count,
    COALESCE(f.distinct_tag_count_forum, 0) AS distinct_tag_count_forum,
    COALESCE(p.distinct_tag_count_post, 0) AS distinct_tag_count_post,
    (COALESCE(f.forum_tag_count, 0) + COALESCE(p.post_tag_count, 0)) AS total_tag_assignments,
    (COALESCE(f.distinct_tag_count_forum, 0) + COALESCE(p.distinct_tag_count_post, 0)) AS total_distinct_tags,
    CASE WHEN COALESCE(f.distinct_tag_count_forum, 0) > 0
         THEN COALESCE(f.forum_tag_count, 0) / CAST(COALESCE(f.distinct_tag_count_forum, 1) AS double)
         ELSE NULL END AS avg_forum_assignments_per_tag,
    CASE WHEN COALESCE(p.distinct_tag_count_post, 0) > 0
         THEN COALESCE(p.post_tag_count, 0) / CAST(COALESCE(p.distinct_tag_count_post, 1) AS double)
         ELSE NULL END AS avg_post_assignments_per_tag
FROM forum_usage f
FULL OUTER JOIN post_usage p
    ON f.tag_class_id = p.tag_class_id
ORDER BY total_tag_assignments DESC
LIMIT 20
