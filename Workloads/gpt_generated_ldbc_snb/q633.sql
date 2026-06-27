WITH comment_tag_likes AS (
    SELECT
        p.id AS creator_id,
        p.first_name,
        p.last_name,
        t.id AS tag_id,
        t.name AS tag_name,
        COUNT(lc.person_id) AS likes_count,
        AVG(c.length) AS avg_comment_length
    FROM comment c
    JOIN person p ON c.creator_person_id = p.id
    JOIN comment_has_tag_tag ct ON ct.comment_id = c.id
    JOIN tag t ON ct.tag_id = t.id
    LEFT JOIN person_likes_comment lc ON lc.comment_id = c.id
    GROUP BY p.id, p.first_name, p.last_name, t.id, t.name
)
SELECT
    creator_id,
    first_name,
    last_name,
    tag_id,
    tag_name,
    likes_count,
    avg_comment_length
FROM (
    SELECT
        creator_id,
        first_name,
        last_name,
        tag_id,
        tag_name,
        likes_count,
        avg_comment_length,
        ROW_NUMBER() OVER (PARTITION BY creator_id ORDER BY likes_count DESC) AS rn
    FROM comment_tag_likes
) sub
WHERE rn <= 3
ORDER BY creator_id, likes_count DESC
