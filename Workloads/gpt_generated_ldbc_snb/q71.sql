WITH tag_usage AS (
    SELECT
        t.id AS tag_id,
        t.name AS tag_name,
        tc.id AS tag_class_id,
        tc.name AS tag_class_name,
        tc.subclass_of_tag_class_id AS parent_tag_class_id,
        COUNT(DISTINCT pct.post_id) AS post_tag_count,
        COUNT(DISTINCT ctt.comment_id) AS comment_tag_count,
        COUNT(DISTINCT ftt.forum_id) AS forum_tag_count,
        COUNT(DISTINCT pit.person_id) AS person_interest_tag_count
    FROM tag t
    LEFT JOIN tag_class tc
        ON t.type_tag_class_id = tc.id
    LEFT JOIN post_has_tag_tag pct
        ON t.id = pct.tag_id
        AND pct.creation_date >= '2023-01-01'
    LEFT JOIN comment_has_tag_tag ctt
        ON t.id = ctt.tag_id
        AND ctt.creation_date >= '2023-01-01'
    LEFT JOIN forum_has_tag_tag ftt
        ON t.id = ftt.tag_id
        AND ftt.creation_date >= '2023-01-01'
    LEFT JOIN person_has_interest_tag pit
        ON t.id = pit.tag_id
        AND pit.creation_date >= '2023-01-01'
    GROUP BY
        t.id,
        t.name,
        tc.id,
        tc.name,
        tc.subclass_of_tag_class_id
)
SELECT
    tag_class_id,
    tag_class_name,
    parent_tag_class_id,
    SUM(post_tag_count) AS total_post_tag_assocs,
    SUM(comment_tag_count) AS total_comment_tag_assocs,
    SUM(forum_tag_count) AS total_forum_tag_assocs,
    SUM(person_interest_tag_count) AS total_person_interest_tag_assocs,
    COUNT(DISTINCT tag_id) AS distinct_tags_in_class
FROM tag_usage
GROUP BY
    tag_class_id,
    tag_class_name,
    parent_tag_class_id
ORDER BY total_post_tag_assocs DESC
LIMIT 10
