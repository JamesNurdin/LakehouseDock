WITH comment_tag_likes AS (
    SELECT
        c.id AS comment_id,
        p.id AS person_id,
        t.id AS tag_id,
        t.name AS tag_name,
        tc.name AS tag_class_name
    FROM comment c
    JOIN comment_has_tag_tag ct ON ct.comment_id = c.id
    JOIN tag t ON ct.tag_id = t.id
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
    JOIN person_likes_comment plc ON plc.comment_id = c.id
    JOIN person p ON plc.person_id = p.id
    JOIN person_has_interest_tag pit ON pit.person_id = p.id AND pit.tag_id = t.id
)
SELECT
    tag_id,
    tag_name,
    tag_class_name,
    COUNT(DISTINCT comment_id) AS liked_comment_count,
    COUNT(DISTINCT person_id) AS distinct_liker_count
FROM comment_tag_likes
GROUP BY
    tag_id,
    tag_name,
    tag_class_name
ORDER BY liked_comment_count DESC
LIMIT 10
