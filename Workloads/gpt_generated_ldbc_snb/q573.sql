SELECT
    tag_class.name AS tag_class_name,
    tag.name AS tag_name,
    COUNT(DISTINCT comment.id) AS comment_count,
    AVG(comment.length) AS avg_comment_length,
    COUNT(DISTINCT comment.creator_person_id) AS distinct_commenters,
    COUNT(DISTINCT post.id) AS distinct_posts
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
JOIN person
  ON forum.moderator_person_id = person.id
WHERE person.gender = 'female'
GROUP BY tag_class.name, tag.name
ORDER BY comment_count DESC
LIMIT 10
