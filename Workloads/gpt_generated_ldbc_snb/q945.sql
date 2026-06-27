WITH entity_tags AS (
    SELECT
        ch.creation_date,
        ch.comment_id AS entity_id,
        ch.tag_id,
        'comment' AS entity_type
    FROM comment_has_tag_tag ch
    UNION ALL
    SELECT
        fh.creation_date,
        fh.forum_id AS entity_id,
        fh.tag_id,
        'forum' AS entity_type
    FROM forum_has_tag_tag fh
    UNION ALL
    SELECT
        ph.creation_date,
        ph.person_id AS entity_id,
        ph.tag_id,
        'person' AS entity_type
    FROM person_has_interest_tag ph
    UNION ALL
    SELECT
        ph.creation_date,
        ph.post_id AS entity_id,
        ph.tag_id,
        'post' AS entity_type
    FROM post_has_tag_tag ph
)
SELECT
    tc.id AS tag_class_id,
    tc.name AS tag_class_name,
    parent_tc.id AS parent_tag_class_id,
    parent_tc.name AS parent_tag_class_name,
    COUNT(*) AS total_assignments,
    SUM(CASE WHEN et.entity_type = 'comment' THEN 1 ELSE 0 END) AS comment_assignments,
    SUM(CASE WHEN et.entity_type = 'forum'   THEN 1 ELSE 0 END) AS forum_assignments,
    SUM(CASE WHEN et.entity_type = 'person'  THEN 1 ELSE 0 END) AS person_assignments,
    SUM(CASE WHEN et.entity_type = 'post'    THEN 1 ELSE 0 END) AS post_assignments
FROM entity_tags et
JOIN tag t
  ON et.tag_id = t.id
JOIN tag_class tc
  ON t.type_tag_class_id = tc.id
LEFT JOIN tag_class parent_tc
  ON tc.subclass_of_tag_class_id = parent_tc.id
GROUP BY
    tc.id,
    tc.name,
    parent_tc.id,
    parent_tc.name
ORDER BY total_assignments DESC
LIMIT 100
