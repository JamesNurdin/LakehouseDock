WITH tag_class_counts AS (
    SELECT
        tc.id AS tag_class_id,
        tc.name AS tag_class_name,
        tc.subclass_of_tag_class_id AS parent_id,
        COUNT(DISTINCT f.id) AS forum_cnt,
        COUNT(DISTINCT cht.comment_id) AS comment_cnt,
        COUNT(DISTINCT pit.person_id) AS person_cnt
    FROM tag_class tc
    LEFT JOIN tag t
        ON t.type_tag_class_id = tc.id
    LEFT JOIN forum_has_tag_tag fht
        ON fht.tag_id = t.id
    LEFT JOIN forum f
        ON f.id = fht.forum_id
    LEFT JOIN comment_has_tag_tag cht
        ON cht.tag_id = t.id
    LEFT JOIN person_has_interest_tag pit
        ON pit.tag_id = t.id
    GROUP BY
        tc.id,
        tc.name,
        tc.subclass_of_tag_class_id
)
SELECT
    COALESCE(parent.id, child.tag_class_id) AS agg_tag_class_id,
    COALESCE(parent.name, child.tag_class_name) AS agg_tag_class_name,
    SUM(child.forum_cnt) AS total_forums,
    SUM(child.comment_cnt) AS total_comments,
    SUM(child.person_cnt) AS total_persons,
    (SUM(child.forum_cnt) + SUM(child.comment_cnt) + SUM(child.person_cnt)) AS total_activity
FROM tag_class_counts child
LEFT JOIN tag_class parent
    ON child.parent_id = parent.id
GROUP BY
    COALESCE(parent.id, child.tag_class_id),
    COALESCE(parent.name, child.tag_class_name)
ORDER BY total_activity DESC
LIMIT 100
