WITH likes_per_post AS (
    SELECT person_likes_post.post_id,
           count(*) AS likes_cnt
    FROM person_likes_post
    GROUP BY person_likes_post.post_id
),
comments_per_post AS (
    SELECT comment.parent_post_id AS post_id,
           count(*) AS comment_cnt,
           avg(comment.length) AS avg_comment_len
    FROM comment
    GROUP BY comment.parent_post_id
),
forum_aggregates AS (
    SELECT forum.id AS forum_id,
           forum.title AS forum_title,
           count(post.id) AS post_cnt,
           sum(post.length) AS total_post_len,
           avg(post.length) AS avg_post_len,
           sum(coalesce(likes_per_post.likes_cnt, 0)) AS total_likes,
           sum(coalesce(comments_per_post.comment_cnt, 0)) AS total_comments,
           avg(coalesce(comments_per_post.avg_comment_len, 0)) AS avg_comment_len,
           count(distinct post.creator_person_id) AS distinct_authors
    FROM forum
    LEFT JOIN post ON post.container_forum_id = forum.id
    LEFT JOIN likes_per_post ON likes_per_post.post_id = post.id
    LEFT JOIN comments_per_post ON comments_per_post.post_id = post.id
    GROUP BY forum.id, forum.title
),
forum_tag_counts AS (
    SELECT forum.id AS forum_id,
           tag.name AS tag_name,
           count(DISTINCT post_has_tag_tag.post_id) AS post_tag_cnt
    FROM forum
    JOIN post ON post.container_forum_id = forum.id
    JOIN post_has_tag_tag ON post_has_tag_tag.post_id = post.id
    JOIN tag ON tag.id = post_has_tag_tag.tag_id
    GROUP BY forum.id, tag.name
),
forum_top_tag AS (
    SELECT forum_tag_counts.forum_id,
           forum_tag_counts.tag_name AS top_tag,
           forum_tag_counts.post_tag_cnt AS top_tag_post_cnt,
           row_number() OVER (PARTITION BY forum_tag_counts.forum_id ORDER BY forum_tag_counts.post_tag_cnt DESC) AS rn
    FROM forum_tag_counts
)
SELECT forum_aggregates.forum_title,
       forum_aggregates.post_cnt,
       forum_aggregates.total_post_len,
       forum_aggregates.avg_post_len,
       forum_aggregates.total_likes,
       forum_aggregates.total_comments,
       forum_aggregates.avg_comment_len,
       forum_aggregates.distinct_authors,
       forum_top_tag.top_tag,
       forum_top_tag.top_tag_post_cnt
FROM forum_aggregates
LEFT JOIN forum_top_tag
  ON forum_top_tag.forum_id = forum_aggregates.forum_id
 AND forum_top_tag.rn = 1
ORDER BY forum_aggregates.total_likes DESC
LIMIT 10
