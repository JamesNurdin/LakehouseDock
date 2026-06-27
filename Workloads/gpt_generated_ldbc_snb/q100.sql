WITH tag_post_stats AS (
    SELECT
        tag.id AS tag_id,
        tag.name AS tag_name,
        COUNT(DISTINCT post.id) AS post_cnt,
        AVG(post.length) AS avg_length,
        COUNT(DISTINCT post.creator_person_id) AS distinct_creator_cnt,
        MAX(post.creation_date) AS latest_creation_date
    FROM post_has_tag_tag
    JOIN post
        ON post_has_tag_tag.post_id = post.id
    JOIN tag
        ON post_has_tag_tag.tag_id = tag.id
    GROUP BY tag.id, tag.name
)
SELECT
    tag_id,
    tag_name,
    post_cnt,
    avg_length,
    distinct_creator_cnt,
    latest_creation_date
FROM tag_post_stats
ORDER BY post_cnt DESC
LIMIT 20
