WITH tag_hierarchy AS (
    SELECT
        tc.id AS tag_class_id,
        tc.name AS tag_class_name,
        COALESCE(parent_tc.id, tc.id) AS root_tag_class_id,
        COALESCE(parent_tc.name, tc.name) AS root_tag_class_name
    FROM tag_class tc
    LEFT JOIN tag_class parent_tc
        ON tc.subclass_of_tag_class_id = parent_tc.id
),
comment_tag AS (
    SELECT
        cht.comment_id,
        cht.creation_date AS comment_creation_date,
        t.id AS tag_id,
        t.type_tag_class_id AS tag_class_id
    FROM comment_has_tag_tag cht
    JOIN tag t
        ON cht.tag_id = t.id
),
person_tag AS (
    SELECT
        pht.person_id,
        pht.creation_date AS person_creation_date,
        t.id AS tag_id,
        t.type_tag_class_id AS tag_class_id
    FROM person_has_interest_tag pht
    JOIN tag t
        ON pht.tag_id = t.id
)
SELECT
    th.root_tag_class_name,
    COUNT(DISTINCT ct.comment_id) AS distinct_comment_count,
    COUNT(DISTINCT pt.person_id) AS distinct_person_count,
    MIN(ct.comment_creation_date) AS earliest_comment_date,
    MAX(ct.comment_creation_date) AS latest_comment_date,
    MIN(pt.person_creation_date) AS earliest_person_date,
    MAX(pt.person_creation_date) AS latest_person_date,
    CASE
        WHEN COUNT(DISTINCT pt.person_id) = 0 THEN NULL
        ELSE CAST(COUNT(DISTINCT ct.comment_id) AS double) / COUNT(DISTINCT pt.person_id)
    END AS comment_to_person_ratio
FROM tag_hierarchy th
LEFT JOIN comment_tag ct
    ON ct.tag_class_id = th.tag_class_id
LEFT JOIN person_tag pt
    ON pt.tag_class_id = th.tag_class_id
GROUP BY th.root_tag_class_name
ORDER BY th.root_tag_class_name
