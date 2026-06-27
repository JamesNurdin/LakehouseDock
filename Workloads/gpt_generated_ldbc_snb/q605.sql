WITH tag_usage AS (
    SELECT
        t.id AS tag_id,
        t.name AS tag_name,
        tc.id AS tag_class_id,
        tc.name AS tag_class_name,
        tc.subclass_of_tag_class_id AS parent_tag_class_id,
        COUNT(DISTINCT cht.comment_id) AS comment_cnt,
        COUNT(DISTINCT pht.post_id) AS post_cnt,
        COUNT(DISTINCT fht.forum_id) AS forum_cnt,
        COUNT(DISTINCT pit.person_id) AS person_cnt
    FROM tag t
    LEFT JOIN tag_class tc
        ON t.type_tag_class_id = tc.id
    LEFT JOIN comment_has_tag_tag cht
        ON cht.tag_id = t.id
    LEFT JOIN post_has_tag_tag pht
        ON pht.tag_id = t.id
    LEFT JOIN forum_has_tag_tag fht
        ON fht.tag_id = t.id
    LEFT JOIN person_has_interest_tag pit
        ON pit.tag_id = t.id
    GROUP BY
        t.id,
        t.name,
        tc.id,
        tc.name,
        tc.subclass_of_tag_class_id
),
tag_usage_with_parent AS (
    SELECT
        tu.*, 
        pc.name AS parent_tag_class_name
    FROM tag_usage tu
    LEFT JOIN tag_class pc
        ON tu.parent_tag_class_id = pc.id
)
SELECT
    tag_class_name,
    parent_tag_class_name,
    tag_name,
    comment_cnt,
    post_cnt,
    forum_cnt,
    person_cnt,
    (comment_cnt + post_cnt + forum_cnt + person_cnt) AS total_usage
FROM tag_usage_with_parent
ORDER BY total_usage DESC
LIMIT 100
