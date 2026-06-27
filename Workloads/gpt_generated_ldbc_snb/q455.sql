WITH tag_with_root_class AS (
    SELECT
        t.id AS tag_id,
        COALESCE(parent_tc.id, tc.id) AS root_class_id,
        COALESCE(parent_tc.name, tc.name) AS root_class_name
    FROM tag t
    JOIN tag_class tc
        ON t.type_tag_class_id = tc.id
    LEFT JOIN tag_class parent_tc
        ON tc.subclass_of_tag_class_id = parent_tc.id
)
SELECT
    twrc.root_class_id,
    twrc.root_class_name,
    COUNT(DISTINCT twrc.tag_id) AS distinct_tag_count,
    COUNT(DISTINCT p.id) AS post_count,
    AVG(p.length) AS avg_post_length,
    COUNT(DISTINCT cht.comment_id) AS comment_count,
    COUNT(DISTINCT fht.forum_id) AS forum_count,
    COUNT(DISTINCT pit.person_id) AS person_interest_count
FROM tag_with_root_class twrc
LEFT JOIN post_has_tag_tag pht
    ON pht.tag_id = twrc.tag_id
LEFT JOIN post p
    ON p.id = pht.post_id
LEFT JOIN comment_has_tag_tag cht
    ON cht.tag_id = twrc.tag_id
LEFT JOIN forum_has_tag_tag fht
    ON fht.tag_id = twrc.tag_id
LEFT JOIN person_has_interest_tag pit
    ON pit.tag_id = twrc.tag_id
GROUP BY
    twrc.root_class_id,
    twrc.root_class_name
ORDER BY post_count DESC
LIMIT 10
