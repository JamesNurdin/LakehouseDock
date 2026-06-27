WITH post_tag AS (
    SELECT
        p.id AS post_id,
        p.length AS post_length,
        p.creator_person_id,
        p.language,
        p.creation_date AS post_creation_date,
        t.id AS tag_id,
        t.name AS tag_name,
        t.type_tag_class_id
    FROM post AS p
    JOIN post_has_tag_tag AS pht
        ON pht.post_id = p.id
    JOIN tag AS t
        ON pht.tag_id = t.id
)
SELECT
    tag_name,
    COUNT(post_id) AS total_posts,
    AVG(post_length) AS avg_post_length,
    COUNT(DISTINCT creator_person_id) AS unique_creators,
    MIN(post_creation_date) AS earliest_post,
    MAX(post_creation_date) AS latest_post
FROM post_tag
GROUP BY tag_name
ORDER BY total_posts DESC
LIMIT 10
