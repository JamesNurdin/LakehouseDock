WITH post_likes AS (
    SELECT
        post.id AS post_id,
        post.container_forum_id AS forum_id,
        post_has_tag_tag.tag_id,
        COUNT(person_likes_post.person_id) AS like_count
    FROM post
    JOIN post_has_tag_tag
        ON post_has_tag_tag.post_id = post.id
    JOIN person_likes_post
        ON person_likes_post.post_id = post.id
    GROUP BY post.id, post.container_forum_id, post_has_tag_tag.tag_id
)
SELECT
    forum.title AS forum_title,
    moderator.first_name AS moderator_first_name,
    moderator.last_name AS moderator_last_name,
    post_likes.tag_id,
    SUM(post_likes.like_count) AS total_likes
FROM post_likes
JOIN forum
    ON forum.id = post_likes.forum_id
JOIN person AS moderator
    ON forum.moderator_person_id = moderator.id
GROUP BY forum.title, moderator.first_name, moderator.last_name, post_likes.tag_id
ORDER BY total_likes DESC
LIMIT 10
