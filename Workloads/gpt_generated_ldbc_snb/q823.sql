WITH tag_class_stats AS (
    SELECT
        tc.id AS tag_class_id,
        tc.name AS tag_class_name,
        tc.subclass_of_tag_class_id AS parent_tag_class_id,
        COUNT(DISTINCT p.id) AS post_count,
        SUM(p.length) AS total_post_length,
        COUNT(DISTINCT p.creator_person_id) AS distinct_post_authors,
        COUNT(DISTINCT c.id) AS comment_count,
        SUM(c.length) AS total_comment_length,
        COUNT(DISTINCT c.creator_person_id) AS distinct_comment_authors,
        COUNT(DISTINCT pit.person_id) AS distinct_interested_persons
    FROM tag_class tc
    LEFT JOIN tag t
        ON t.type_tag_class_id = tc.id
    LEFT JOIN post_has_tag_tag pht
        ON pht.tag_id = t.id
    LEFT JOIN post p
        ON p.id = pht.post_id
    LEFT JOIN comment_has_tag_tag cht
        ON cht.tag_id = t.id
    LEFT JOIN comment c
        ON c.id = cht.comment_id
    LEFT JOIN person_has_interest_tag pit
        ON pit.tag_id = t.id
    GROUP BY
        tc.id,
        tc.name,
        tc.subclass_of_tag_class_id
)
SELECT
    tag_class_id,
    tag_class_name,
    parent_tag_class_id,
    post_count,
    total_post_length,
    distinct_post_authors,
    comment_count,
    total_comment_length,
    distinct_comment_authors,
    distinct_interested_persons
FROM tag_class_stats
ORDER BY post_count DESC, comment_count DESC
LIMIT 100
