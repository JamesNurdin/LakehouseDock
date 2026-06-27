WITH comment_tag_forum AS (
    SELECT
        comment.id AS comment_id,
        comment.length AS comment_length,
        comment.creator_person_id AS creator_person_id,
        post.container_forum_id AS forum_id,
        forum.title AS forum_title,
        tag.id AS tag_id,
        tag.name AS tag_name,
        tag_class.id AS tag_class_id,
        tag_class.name AS tag_class_name
    FROM comment
    JOIN comment_has_tag_tag
        ON comment_has_tag_tag.comment_id = comment.id
    JOIN tag
        ON comment_has_tag_tag.tag_id = tag.id
    JOIN tag_class
        ON tag.type_tag_class_id = tag_class.id
    JOIN post
        ON comment.parent_post_id = post.id
    JOIN forum
        ON post.container_forum_id = forum.id
)
SELECT
    ctf.forum_id,
    ctf.forum_title,
    ctf.tag_class_id,
    ctf.tag_class_name,
    ctf.tag_id,
    ctf.tag_name,
    COUNT(DISTINCT plc.person_id) AS unique_likers,
    COUNT(DISTINCT ctf.comment_id) AS comment_count,
    SUM(ctf.comment_length) / COUNT(DISTINCT ctf.comment_id) AS avg_comment_length,
    COUNT(DISTINCT ctf.creator_person_id) AS unique_commenters
FROM comment_tag_forum ctf
LEFT JOIN person_likes_comment plc
    ON plc.comment_id = ctf.comment_id
GROUP BY
    ctf.forum_id,
    ctf.forum_title,
    ctf.tag_class_id,
    ctf.tag_class_name,
    ctf.tag_id,
    ctf.tag_name
ORDER BY unique_likers DESC
LIMIT 100
