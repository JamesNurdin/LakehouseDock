WITH comment_tags AS (
    SELECT
        c.id AS comment_id,
        c.length AS comment_length,
        p.id AS person_id,
        p.gender AS creator_gender,
        t.id AS tag_id,
        t.name AS tag_name,
        tc.id AS tag_class_id,
        tc.name AS tag_class_name
    FROM comment c
    JOIN comment_has_tag_tag ct
        ON ct.comment_id = c.id
    JOIN tag t
        ON t.id = ct.tag_id
    JOIN tag_class tc
        ON tc.id = t.type_tag_class_id
    JOIN person p
        ON p.id = c.creator_person_id
    JOIN person_has_interest_tag pit
        ON pit.person_id = p.id
        AND pit.tag_id = t.id
    JOIN post po
        ON po.id = c.parent_post_id
    JOIN forum f
        ON f.id = po.container_forum_id
    JOIN forum_has_member_person fmp
        ON fmp.forum_id = f.id
        AND fmp.person_id = p.id
    WHERE p.gender = 'female'
      AND c.length > 100
)
SELECT
    tag_class_name,
    COUNT(DISTINCT comment_id) AS comment_count,
    AVG(comment_length) AS avg_comment_length
FROM comment_tags
GROUP BY tag_class_name
ORDER BY comment_count DESC
LIMIT 10
