SELECT
    forum.title AS forum_title,
    tag.name AS tag_name,
    person.gender,
    AVG(comment.length) AS avg_comment_length,
    COUNT(comment.id) AS comment_count
FROM comment
JOIN post
  ON comment.parent_post_id = post.id
JOIN forum
  ON post.container_forum_id = forum.id
JOIN post_has_tag_tag
  ON post.id = post_has_tag_tag.post_id
JOIN tag
  ON post_has_tag_tag.tag_id = tag.id
JOIN tag_class
  ON tag.type_tag_class_id = tag_class.id
JOIN person
  ON comment.creator_person_id = person.id
WHERE tag_class.name = 'Topic'
GROUP BY forum.title, tag.name, person.gender
ORDER BY comment_count DESC
LIMIT 100
