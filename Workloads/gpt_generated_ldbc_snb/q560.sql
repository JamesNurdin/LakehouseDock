WITH comment_metrics AS (
    SELECT
        forum.id AS forum_id,
        forum.title AS forum_title,
        comment.id AS comment_id,
        comment.length AS comment_length,
        person.gender AS creator_gender,
        comment_has_tag_tag.tag_id AS comment_tag_id,
        tag.type_tag_class_id AS comment_tag_class_id
    FROM comment
    JOIN post ON comment.parent_post_id = post.id
    JOIN forum ON post.container_forum_id = forum.id
    JOIN person ON comment.creator_person_id = person.id
    LEFT JOIN comment_has_tag_tag ON comment.id = comment_has_tag_tag.comment_id
    LEFT JOIN tag ON comment_has_tag_tag.tag_id = tag.id
)
SELECT
    forum_id,
    forum_title,
    COUNT(comment_id) AS total_comments,
    AVG(comment_length) AS avg_comment_length,
    COUNT(DISTINCT comment_tag_id) AS distinct_comment_tags,
    COUNT(DISTINCT comment_tag_class_id) AS distinct_comment_tag_classes,
    SUM(CASE WHEN creator_gender = 'male' THEN 1 ELSE 0 END) AS male_comments,
    SUM(CASE WHEN creator_gender = 'female' THEN 1 ELSE 0 END) AS female_comments
FROM comment_metrics
GROUP BY forum_id, forum_title
ORDER BY total_comments DESC
LIMIT 10
