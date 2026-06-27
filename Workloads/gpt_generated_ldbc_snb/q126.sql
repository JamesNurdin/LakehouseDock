WITH reply_comment_tags AS (
    SELECT
        c.id AS comment_id,
        c.length AS comment_length,
        t.id AS tag_id,
        t.type_tag_class_id AS tag_class_id
    FROM comment c
    JOIN comment p ON p.id = c.parent_comment_id
    JOIN comment_has_tag_tag cht ON cht.comment_id = c.id
    JOIN tag t ON t.id = cht.tag_id
),
person_interest AS (
    SELECT
        pht.person_id,
        t.type_tag_class_id AS tag_class_id
    FROM person_has_interest_tag pht
    JOIN tag t ON t.id = pht.tag_id
),
tag_class_hierarchy AS (
    SELECT
        tc.id AS tag_class_id,
        tc.name AS tag_class_name,
        pc.id AS parent_tag_class_id,
        pc.name AS parent_tag_class_name
    FROM tag_class tc
    LEFT JOIN tag_class pc ON pc.id = tc.subclass_of_tag_class_id
)
SELECT
    tch.tag_class_id,
    tch.tag_class_name,
    tch.parent_tag_class_name,
    COUNT(DISTINCT rct.comment_id) AS reply_comment_count,
    AVG(rct.comment_length) AS avg_reply_comment_length,
    COUNT(DISTINCT rct.tag_id) AS distinct_tag_count,
    COUNT(DISTINCT pi.person_id) AS interested_person_count
FROM reply_comment_tags rct
JOIN tag_class_hierarchy tch ON tch.tag_class_id = rct.tag_class_id
LEFT JOIN person_interest pi ON pi.tag_class_id = tch.tag_class_id
GROUP BY
    tch.tag_class_id,
    tch.tag_class_name,
    tch.parent_tag_class_name
ORDER BY reply_comment_count DESC
LIMIT 10
