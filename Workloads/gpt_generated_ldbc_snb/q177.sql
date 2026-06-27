WITH comment_metrics AS (
    SELECT
        tc.id AS tag_class_id,
        tc.name AS tag_class_name,
        COUNT(DISTINCT c.id) AS comment_count,
        AVG(c.length) AS avg_comment_length,
        COUNT(DISTINCT t.id) AS distinct_comment_tag_count
    FROM comment_has_tag_tag cht
    JOIN comment c ON cht.comment_id = c.id
    JOIN tag t ON cht.tag_id = t.id
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
    GROUP BY tc.id, tc.name
),
interest_metrics AS (
    SELECT
        tc.id AS tag_class_id,
        COUNT(DISTINCT pht.person_id) AS interested_person_count,
        COUNT(DISTINCT t.id) AS distinct_interest_tag_count
    FROM person_has_interest_tag pht
    JOIN tag t ON pht.tag_id = t.id
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
    GROUP BY tc.id
),
subclass_counts AS (
    SELECT
        parent.id AS parent_tag_class_id,
        COUNT(DISTINCT child.id) AS subclass_count
    FROM tag_class child
    JOIN tag_class parent ON child.subclass_of_tag_class_id = parent.id
    GROUP BY parent.id
)
SELECT
    cm.tag_class_id,
    cm.tag_class_name,
    cm.comment_count,
    cm.avg_comment_length,
    cm.distinct_comment_tag_count,
    im.interested_person_count,
    im.distinct_interest_tag_count,
    sc.subclass_count
FROM comment_metrics cm
LEFT JOIN interest_metrics im
    ON cm.tag_class_id = im.tag_class_id
LEFT JOIN subclass_counts sc
    ON cm.tag_class_id = sc.parent_tag_class_id
ORDER BY cm.comment_count DESC
LIMIT 20
