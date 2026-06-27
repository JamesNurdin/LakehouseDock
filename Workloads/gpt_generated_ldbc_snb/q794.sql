WITH comment_like_counts AS (
    SELECT
        comment_id,
        COUNT(*) AS like_cnt
    FROM person_likes_comment
    GROUP BY comment_id
)
SELECT
    forum.id AS forum_id,
    forum.title AS forum_title,
    mod.gender AS moderator_gender,
    creator.gender AS creator_gender,
    COUNT(DISTINCT comment.id) AS comment_count,
    SUM(COALESCE(clc.like_cnt, 0)) AS total_comment_likes,
    AVG(comment.length) AS avg_comment_length
FROM forum
JOIN post
    ON post.container_forum_id = forum.id
JOIN comment
    ON comment.parent_post_id = post.id
JOIN person AS creator
    ON creator.id = comment.creator_person_id
JOIN person AS mod
    ON mod.id = forum.moderator_person_id
LEFT JOIN comment_like_counts AS clc
    ON clc.comment_id = comment.id
GROUP BY
    forum.id,
    forum.title,
    mod.gender,
    creator.gender
ORDER BY total_comment_likes DESC
LIMIT 10
