WITH tag_hierarchy AS (
    SELECT
        tc.id AS tag_class_id,
        tc.name AS tag_class_name,
        parent.id AS parent_tag_class_id,
        parent.name AS parent_tag_class_name
    FROM tag_class tc
    LEFT JOIN tag_class parent
        ON tc.subclass_of_tag_class_id = parent.id
),
comment_activity AS (
    SELECT
        tc.id AS tag_class_id,
        COUNT(DISTINCT cht.comment_id) AS comment_cnt
    FROM comment_has_tag_tag cht
    JOIN tag t
        ON cht.tag_id = t.id
    JOIN tag_class tc
        ON t.type_tag_class_id = tc.id
    GROUP BY tc.id
),
post_activity AS (
    SELECT
        tc.id AS tag_class_id,
        COUNT(DISTINCT pht.post_id) AS post_cnt
    FROM post_has_tag_tag pht
    JOIN tag t
        ON pht.tag_id = t.id
    JOIN tag_class tc
        ON t.type_tag_class_id = tc.id
    GROUP BY tc.id
),
person_activity AS (
    SELECT
        tc.id AS tag_class_id,
        COUNT(DISTINCT pit.person_id) AS person_cnt
    FROM person_has_interest_tag pit
    JOIN tag t
        ON pit.tag_id = t.id
    JOIN tag_class tc
        ON t.type_tag_class_id = tc.id
    GROUP BY tc.id
)
SELECT
    th.tag_class_id,
    th.tag_class_name,
    th.parent_tag_class_id,
    th.parent_tag_class_name,
    COALESCE(ca.comment_cnt, 0) AS comment_cnt,
    COALESCE(pa.post_cnt, 0) AS post_cnt,
    COALESCE(pia.person_cnt, 0) AS person_cnt,
    (COALESCE(ca.comment_cnt, 0) + COALESCE(pa.post_cnt, 0) + COALESCE(pia.person_cnt, 0)) AS total_activity
FROM tag_hierarchy th
LEFT JOIN comment_activity ca
    ON th.tag_class_id = ca.tag_class_id
LEFT JOIN post_activity pa
    ON th.tag_class_id = pa.tag_class_id
LEFT JOIN person_activity pia
    ON th.tag_class_id = pia.tag_class_id
ORDER BY total_activity DESC
LIMIT 10
