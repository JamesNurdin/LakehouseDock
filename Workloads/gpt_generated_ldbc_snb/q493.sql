WITH person_tag_class AS (
    SELECT
        pht.person_id,
        tc.id AS tag_class_id,
        tc.name AS tag_class_name,
        tc.subclass_of_tag_class_id AS parent_tag_class_id
    FROM person_has_interest_tag pht
    JOIN tag t
        ON pht.tag_id = t.id
    JOIN tag_class tc
        ON t.type_tag_class_id = tc.id
)
SELECT
    COALESCE(parent_tc.name, 'Root') AS parent_tag_class_name,
    ptc.tag_class_name,
    COUNT(DISTINCT ptc.person_id) AS distinct_persons,
    COUNT(*) AS interest_links
FROM person_tag_class ptc
LEFT JOIN tag_class parent_tc
    ON ptc.parent_tag_class_id = parent_tc.id
GROUP BY
    COALESCE(parent_tc.name, 'Root'),
    ptc.tag_class_name
ORDER BY distinct_persons DESC
LIMIT 10
