WITH tag_class_hierarchy AS (
    -- Tags that belong directly to a class
    SELECT
        tc.id AS tag_class_id,
        t.id AS tag_id
    FROM tag t
    JOIN tag_class tc
        ON t.type_tag_class_id = tc.id

    UNION ALL

    -- Tags that belong to an immediate subclass of a class
    SELECT
        parent_tc.id AS tag_class_id,
        t.id AS tag_id
    FROM tag t
    JOIN tag_class child_tc
        ON t.type_tag_class_id = child_tc.id
    JOIN tag_class parent_tc
        ON child_tc.subclass_of_tag_class_id = parent_tc.id
)
SELECT
    tc.id AS tag_class_id,
    tc.name AS tag_class_name,
    COUNT(DISTINCT th.tag_id) AS num_tags,
    COUNT(DISTINCT pht.post_id) AS total_posts_tagged,
    COUNT(DISTINCT cht.comment_id) AS total_comments_tagged,
    COUNT(DISTINCT fht.forum_id) AS total_forums_tagged,
    COUNT(DISTINCT pih.person_id) AS total_persons_interested
FROM tag_class tc
LEFT JOIN tag_class_hierarchy th
    ON th.tag_class_id = tc.id
LEFT JOIN post_has_tag_tag pht
    ON pht.tag_id = th.tag_id
LEFT JOIN comment_has_tag_tag cht
    ON cht.tag_id = th.tag_id
LEFT JOIN forum_has_tag_tag fht
    ON fht.tag_id = th.tag_id
LEFT JOIN person_has_interest_tag pih
    ON pih.tag_id = th.tag_id
GROUP BY tc.id, tc.name
ORDER BY total_posts_tagged DESC
LIMIT 10
