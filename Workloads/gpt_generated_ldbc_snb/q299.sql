WITH likes_per_post AS (
    SELECT
        post.id AS post_id,
        COUNT(person_likes_post.person_id) AS like_count
    FROM person_likes_post
    JOIN post
        ON person_likes_post.post_id = post.id
    GROUP BY post.id
),
post_tags AS (
    SELECT
        post.id AS post_id,
        tag.id AS tag_id,
        tag.name AS tag_name,
        post.container_forum_id AS forum_id
    FROM post
    JOIN post_has_tag_tag
        ON post_has_tag_tag.post_id = post.id
    JOIN tag
        ON post_has_tag_tag.tag_id = tag.id
)
SELECT
    forum.title AS forum_title,
    post_tags.tag_name,
    SUM(likes_per_post.like_count) AS total_likes
FROM likes_per_post
JOIN post_tags
    ON likes_per_post.post_id = post_tags.post_id
JOIN forum
    ON post_tags.forum_id = forum.id
GROUP BY forum.title, post_tags.tag_name
ORDER BY total_likes DESC
LIMIT 10
