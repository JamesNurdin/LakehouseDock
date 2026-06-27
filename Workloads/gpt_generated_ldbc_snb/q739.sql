WITH tag_usage AS (
    SELECT t.id AS tag_id,
           t.type_tag_class_id AS tag_class_id,
           COUNT(DISTINCT cht.comment_id) AS comment_cnt,
           COUNT(DISTINCT fht.forum_id)   AS forum_cnt,
           COUNT(DISTINCT pht.post_id)    AS post_cnt,
           COUNT(DISTINCT pit.person_id) AS person_cnt
    FROM tag t
    LEFT JOIN comment_has_tag_tag cht ON cht.tag_id = t.id
    LEFT JOIN forum_has_tag_tag fht   ON fht.tag_id = t.id
    LEFT JOIN post_has_tag_tag pht    ON pht.tag_id = t.id
    LEFT JOIN person_has_interest_tag pit ON pit.tag_id = t.id
    GROUP BY t.id, t.type_tag_class_id
)
SELECT COALESCE(parent_tc.id, child_tc.id)   AS tag_class_id,
       COALESCE(parent_tc.name, child_tc.name) AS tag_class_name,
       SUM(tu.comment_cnt)   AS total_comments,
       SUM(tu.forum_cnt)     AS total_forums,
       SUM(tu.post_cnt)      AS total_posts,
       SUM(tu.person_cnt)    AS total_person_interests,
       COUNT(DISTINCT tu.tag_id) AS distinct_tags
FROM tag_usage tu
JOIN tag_class child_tc ON child_tc.id = tu.tag_class_id
LEFT JOIN tag_class parent_tc ON parent_tc.id = child_tc.subclass_of_tag_class_id
GROUP BY COALESCE(parent_tc.id, child_tc.id), COALESCE(parent_tc.name, child_tc.name)
ORDER BY total_comments DESC
LIMIT 5
