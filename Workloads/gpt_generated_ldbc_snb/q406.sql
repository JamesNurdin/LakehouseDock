WITH tag_metrics AS (
    SELECT
        tc.id AS tag_class_id,
        tc.name AS tag_class_name,
        parent_tc.name AS parent_tag_class_name,
        t.id AS tag_id,
        p.id AS post_id,
        cht.comment_id,
        pi.person_id
    FROM tag_class tc
    LEFT JOIN tag_class parent_tc
        ON tc.subclass_of_tag_class_id = parent_tc.id
    JOIN tag t
        ON t.type_tag_class_id = tc.id
    LEFT JOIN post_has_tag_tag pht
        ON pht.tag_id = t.id
    LEFT JOIN post p
        ON p.id = pht.post_id
    LEFT JOIN comment_has_tag_tag cht
        ON cht.tag_id = t.id
    LEFT JOIN person_has_interest_tag pi
        ON pi.tag_id = t.id
)
SELECT
    tag_class_id,
    tag_class_name,
    parent_tag_class_name,
    COUNT(DISTINCT tag_id) AS distinct_tag_count,
    COUNT(DISTINCT post_id) AS distinct_post_count,
    COUNT(DISTINCT comment_id) AS distinct_comment_count,
    COUNT(DISTINCT person_id) AS distinct_person_interest_count
FROM tag_metrics
GROUP BY tag_class_id, tag_class_name, parent_tag_class_name
ORDER BY distinct_post_count DESC
LIMIT 100
