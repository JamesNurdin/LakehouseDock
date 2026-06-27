WITH tag_hierarchy AS (
    SELECT
        t.id AS tag_id,
        t.name AS tag_name,
        t.url AS tag_url,
        tc.id AS tag_class_id,
        tc.name AS tag_class_name,
        tc.url AS tag_class_url,
        pc.id AS parent_tag_class_id,
        pc.name AS parent_tag_class_name,
        pc.url AS parent_tag_class_url
    FROM tag t
    JOIN tag_class tc
        ON t.type_tag_class_id = tc.id
    LEFT JOIN tag_class pc
        ON tc.subclass_of_tag_class_id = pc.id
)
SELECT
    th.parent_tag_class_name,
    th.tag_class_name,
    th.tag_name,
    COUNT(DISTINCT pht.post_id) AS distinct_post_count,
    MIN(pht.creation_date) AS earliest_creation_date,
    MAX(pht.creation_date) AS latest_creation_date
FROM post_has_tag_tag pht
JOIN tag_hierarchy th
    ON pht.tag_id = th.tag_id
GROUP BY
    th.parent_tag_class_name,
    th.tag_class_name,
    th.tag_name
ORDER BY distinct_post_count DESC
LIMIT 100
