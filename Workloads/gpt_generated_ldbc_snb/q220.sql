WITH likes_per_post AS (
    SELECT
        post_id,
        COUNT(*) AS like_count
    FROM person_likes_post
    GROUP BY post_id
)
SELECT
    creator.id AS creator_id,
    creator.gender,
    COUNT(DISTINCT post.id) AS posts_created,
    SUM(COALESCE(lpp.like_count, 0)) AS total_likes_received,
    AVG(COALESCE(lpp.like_count, 0)) AS avg_likes_per_post,
    AVG(post.length) AS avg_post_length,
    COUNT(DISTINCT CASE WHEN lpp.like_count > 0 THEN post.id END) AS posts_with_likes
FROM post
JOIN person AS creator
    ON post.creator_person_id = creator.id
LEFT JOIN likes_per_post lpp
    ON post.id = lpp.post_id
GROUP BY creator.id, creator.gender
ORDER BY avg_likes_per_post DESC
LIMIT 10
