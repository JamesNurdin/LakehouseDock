WITH comment_usage AS (
    SELECT tag_id,
           COUNT(DISTINCT comment_id) AS comment_cnt
    FROM comment_has_tag_tag
    GROUP BY tag_id
),
forum_usage AS (
    SELECT tag_id,
           COUNT(DISTINCT forum_id) AS forum_cnt
    FROM forum_has_tag_tag
    GROUP BY tag_id
),
person_usage AS (
    SELECT tag_id,
           COUNT(DISTINCT person_id) AS person_cnt
    FROM person_has_interest_tag
    GROUP BY tag_id
),
post_usage AS (
    SELECT tag_id,
           COUNT(DISTINCT post_id) AS post_cnt
    FROM post_has_tag_tag
    GROUP BY tag_id
),
tag_usage AS (
    SELECT
        t.id AS tag_id,
        t.name AS tag_name,
        t.type_tag_class_id AS tag_class_id,
        COALESCE(cu.comment_cnt, 0) AS comment_cnt,
        COALESCE(fu.forum_cnt, 0) AS forum_cnt,
        COALESCE(pu.person_cnt, 0) AS person_cnt,
        COALESCE(po.post_cnt, 0) AS post_cnt
    FROM tag t
    LEFT JOIN comment_usage cu ON cu.tag_id = t.id
    LEFT JOIN forum_usage fu ON fu.tag_id = t.id
    LEFT JOIN person_usage pu ON pu.tag_id = t.id
    LEFT JOIN post_usage po ON po.tag_id = t.id
)
SELECT
    tc.id AS tag_class_id,
    tc.name AS tag_class_name,
    parent_tc.name AS parent_class_name,
    tu.tag_id,
    tu.tag_name,
    tu.comment_cnt,
    tu.forum_cnt,
    tu.person_cnt,
    tu.post_cnt,
    (tu.comment_cnt + tu.forum_cnt + tu.person_cnt + tu.post_cnt) AS total_usage
FROM tag_usage tu
JOIN tag_class tc ON tu.tag_class_id = tc.id
LEFT JOIN tag_class parent_tc ON tc.subclass_of_tag_class_id = parent_tc.id
ORDER BY total_usage DESC
LIMIT 100
