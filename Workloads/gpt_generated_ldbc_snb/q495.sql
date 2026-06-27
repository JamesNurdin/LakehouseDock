WITH tag_class_hierarchy AS (
    SELECT
        tc.id AS class_id,
        tc.name AS class_name,
        COALESCE(parent_tc.id, -1) AS parent_class_id,
        COALESCE(parent_tc.name, 'ROOT') AS parent_class_name
    FROM tag_class tc
    LEFT JOIN tag_class parent_tc
        ON tc.subclass_of_tag_class_id = parent_tc.id
)
SELECT
    tc_h.parent_class_name,
    tc_h.class_name,
    COUNT(DISTINCT p.id) AS distinct_persons,
    COUNT(DISTINCT ph.post_id) AS distinct_posts
FROM tag_class_hierarchy tc_h
LEFT JOIN tag t
    ON t.type_tag_class_id = tc_h.class_id
LEFT JOIN person_has_interest_tag pht
    ON pht.tag_id = t.id
LEFT JOIN person p
    ON p.id = pht.person_id
LEFT JOIN post_has_tag_tag ph
    ON ph.tag_id = t.id
GROUP BY
    tc_h.parent_class_name,
    tc_h.class_name
ORDER BY
    distinct_persons DESC,
    distinct_posts DESC
LIMIT 20
