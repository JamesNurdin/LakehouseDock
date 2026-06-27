WITH matched_posts AS (
    SELECT
        tc.id AS tag_class_id,
        tc.name AS tag_class_name,
        p.id AS post_id,
        per.id AS person_id,
        p.length AS post_length
    FROM post_has_tag_tag AS pht
    JOIN post AS p ON pht.post_id = p.id
    JOIN person AS per ON p.creator_person_id = per.id
    JOIN tag AS t ON pht.tag_id = t.id
    JOIN person_has_interest_tag AS pit ON pit.person_id = per.id AND pit.tag_id = t.id
    JOIN tag_class AS tc ON t.type_tag_class_id = tc.id
)
SELECT
    tag_class_id,
    tag_class_name,
    COUNT(DISTINCT post_id) AS matching_posts,
    COUNT(DISTINCT person_id) AS matching_creators,
    AVG(post_length) AS avg_post_length
FROM matched_posts
GROUP BY tag_class_id, tag_class_name
ORDER BY matching_posts DESC
LIMIT 10
