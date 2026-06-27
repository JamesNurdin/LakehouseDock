WITH tag_stats AS (
    SELECT
        tag.id AS tag_id,
        tag.name AS tag_name,
        COUNT(DISTINCT post.id) AS post_count,
        COUNT(DISTINCT person.id) AS creator_count,
        AVG(post.length) AS avg_length
    FROM post_has_tag_tag
    JOIN post
        ON post_has_tag_tag.post_id = post.id
    JOIN tag
        ON post_has_tag_tag.tag_id = tag.id
    JOIN person
        ON post.creator_person_id = person.id
    WHERE person.gender = 'female'
    GROUP BY tag.id, tag.name
)
SELECT
    tag_id,
    tag_name,
    post_count,
    creator_count,
    avg_length
FROM tag_stats
ORDER BY post_count DESC
LIMIT 10
