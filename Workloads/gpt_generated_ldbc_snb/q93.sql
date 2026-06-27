WITH forum_mod AS (
    SELECT
        forum.id AS forum_id,
        forum.title,
        person.gender AS moderator_gender
    FROM forum
    JOIN person ON forum.moderator_person_id = person.id
),
forum_posts AS (
    SELECT
        post.container_forum_id AS forum_id,
        COUNT(*) AS post_count,
        AVG(post.length) AS avg_post_length
    FROM post
    GROUP BY post.container_forum_id
),
forum_post_tag_classes AS (
    SELECT
        post.container_forum_id AS forum_id,
        COUNT(DISTINCT tag_class.id) AS distinct_post_tag_classes
    FROM post
    JOIN post_has_tag_tag ON post.id = post_has_tag_tag.post_id
    JOIN tag ON post_has_tag_tag.tag_id = tag.id
    JOIN tag_class ON tag.type_tag_class_id = tag_class.id
    GROUP BY post.container_forum_id
),
forum_comments AS (
    SELECT
        post.container_forum_id AS forum_id,
        COUNT(comment.id) AS comment_count
    FROM comment
    JOIN post ON comment.parent_post_id = post.id
    GROUP BY post.container_forum_id
),
forum_comment_tag_classes AS (
    SELECT
        post.container_forum_id AS forum_id,
        COUNT(DISTINCT tag_class.id) AS distinct_comment_tag_classes
    FROM comment
    JOIN post ON comment.parent_post_id = post.id
    JOIN comment_has_tag_tag ON comment.id = comment_has_tag_tag.comment_id
    JOIN tag ON comment_has_tag_tag.tag_id = tag.id
    JOIN tag_class ON tag.type_tag_class_id = tag_class.id
    GROUP BY post.container_forum_id
)
SELECT
    f.forum_id,
    f.title,
    f.moderator_gender,
    p.post_count,
    p.avg_post_length,
    ptc.distinct_post_tag_classes,
    c.comment_count,
    ctc.distinct_comment_tag_classes
FROM forum_mod f
LEFT JOIN forum_posts p ON f.forum_id = p.forum_id
LEFT JOIN forum_post_tag_classes ptc ON f.forum_id = ptc.forum_id
LEFT JOIN forum_comments c ON f.forum_id = c.forum_id
LEFT JOIN forum_comment_tag_classes ctc ON f.forum_id = ctc.forum_id
ORDER BY f.forum_id
