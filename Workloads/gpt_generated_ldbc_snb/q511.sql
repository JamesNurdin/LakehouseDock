WITH comment_like_counts AS (
    SELECT comment_id,
           COUNT(*) AS like_count
    FROM person_likes_comment
    GROUP BY comment_id
)
SELECT
    forum.id AS forum_id,
    forum.title,
    forum.creation_date,
    COUNT(DISTINCT comment.id)                AS comment_count,
    SUM(COALESCE(comment_like_counts.like_count, 0)) AS total_likes,
    AVG(comment.length)                      AS avg_comment_length,
    COUNT(DISTINCT comment_has_tag_tag.tag_id) AS distinct_tag_count
FROM forum
JOIN post
  ON post.container_forum_id = forum.id
JOIN comment
  ON comment.parent_post_id = post.id
LEFT JOIN comment_like_counts
  ON comment_like_counts.comment_id = comment.id
LEFT JOIN comment_has_tag_tag
  ON comment_has_tag_tag.comment_id = comment.id
GROUP BY forum.id,
         forum.title,
         forum.creation_date
ORDER BY total_likes DESC
LIMIT 10
