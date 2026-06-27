-- Top 10 creators whose posts have received the most likes
WITH likes_per_post AS (
    SELECT
        person_likes_post.post_id,
        COUNT(*) AS likes_count
    FROM person_likes_post
    GROUP BY person_likes_post.post_id
)
SELECT
    person.id AS person_id,
    person.first_name,
    person.last_name,
    person.gender,
    COUNT(DISTINCT post.id) AS total_posts,
    SUM(likes_per_post.likes_count) AS total_likes_received,
    AVG(likes_per_post.likes_count) AS avg_likes_per_post,
    AVG(post.length) AS avg_post_length
FROM post
JOIN likes_per_post
    ON post.id = likes_per_post.post_id
JOIN person
    ON post.creator_person_id = person.id
GROUP BY
    person.id,
    person.first_name,
    person.last_name,
    person.gender
ORDER BY total_likes_received DESC
LIMIT 10
