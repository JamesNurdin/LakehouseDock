-- Top tags by average post length per gender (minimum 10 posts)
WITH tag_post_stats AS (
    SELECT
        t.id AS tag_id,
        t.name AS tag_name,
        p.gender,
        COUNT(*) AS post_count,
        AVG(post.length) AS avg_post_length,
        SUM(post.length) AS total_post_length,
        COUNT(DISTINCT post.creator_person_id) AS distinct_authors
    FROM post_has_tag_tag pt
    JOIN post ON pt.post_id = post.id
    JOIN tag t ON pt.tag_id = t.id
    JOIN person p ON post.creator_person_id = p.id
    GROUP BY t.id, t.name, p.gender
)
SELECT
    tag_id,
    tag_name,
    gender,
    post_count,
    avg_post_length,
    total_post_length,
    distinct_authors
FROM tag_post_stats
WHERE post_count >= 10
ORDER BY avg_post_length DESC
LIMIT 20
