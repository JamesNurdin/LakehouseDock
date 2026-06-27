WITH post_tag_counts AS (
    SELECT
        p.id AS post_id,
        p.length AS post_length,
        p.creator_person_id,
        p.container_forum_id,
        t.id AS tag_id,
        t.name AS tag_name,
        tc.id AS tag_class_id,
        tc.name AS tag_class_name
    FROM post p
    JOIN post_has_tag_tag pt ON pt.post_id = p.id
    JOIN tag t ON t.id = pt.tag_id
    JOIN tag_class tc ON tc.id = t.type_tag_class_id
),
comment_tag_counts AS (
    SELECT
        c.id AS comment_id,
        c.length AS comment_length,
        c.creator_person_id AS comment_creator_person_id,
        c.parent_post_id,
        t.id AS tag_id,
        t.name AS tag_name,
        tc.id AS tag_class_id,
        tc.name AS tag_class_name
    FROM comment c
    JOIN comment_has_tag_tag ct ON ct.comment_id = c.id
    JOIN tag t ON t.id = ct.tag_id
    JOIN tag_class tc ON tc.id = t.type_tag_class_id
),
person_interest_counts AS (
    SELECT
        p.id AS person_id,
        p.gender,
        t.id AS tag_id,
        t.name AS tag_name,
        tc.id AS tag_class_id,
        tc.name AS tag_class_name
    FROM person p
    JOIN person_has_interest_tag pit ON pit.person_id = p.id
    JOIN tag t ON t.id = pit.tag_id
    JOIN tag_class tc ON tc.id = t.type_tag_class_id
)
SELECT
    tc.id AS tag_class_id,
    tc.name AS tag_class_name,
    COUNT(DISTINCT pt.post_id) AS post_count,
    AVG(pt.post_length) AS avg_post_length,
    COUNT(DISTINCT ct.comment_id) AS comment_count,
    AVG(ct.comment_length) AS avg_comment_length,
    COUNT(DISTINCT pi.person_id) AS person_interest_count,
    COUNT(DISTINCT pt.container_forum_id) AS forum_count,
    COUNT(DISTINCT pt.tag_id) AS distinct_post_tag_count,
    COUNT(DISTINCT ct.tag_id) AS distinct_comment_tag_count
FROM tag_class tc
LEFT JOIN post_tag_counts pt ON pt.tag_class_id = tc.id
LEFT JOIN comment_tag_counts ct ON ct.tag_class_id = tc.id
LEFT JOIN person_interest_counts pi ON pi.tag_class_id = tc.id
GROUP BY tc.id, tc.name
ORDER BY post_count DESC
LIMIT 20
