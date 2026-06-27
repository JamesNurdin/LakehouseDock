WITH member_counts AS (
    SELECT forum_has_member_person.forum_id AS forum_id,
           COUNT(DISTINCT forum_has_member_person.person_id) AS member_count
    FROM forum_has_member_person
    GROUP BY forum_has_member_person.forum_id
),
member_interests AS (
    SELECT forum_has_member_person.forum_id AS forum_id,
           COUNT(DISTINCT person_has_interest_tag.tag_id) AS distinct_interest_tag_count
    FROM forum_has_member_person
    JOIN person ON forum_has_member_person.person_id = person.id
    JOIN person_has_interest_tag ON person_has_interest_tag.person_id = person.id
    GROUP BY forum_has_member_person.forum_id
),
post_stats AS (
    SELECT post.container_forum_id AS forum_id,
           COUNT(*) AS post_count,
           AVG(post.length) AS avg_post_length
    FROM post
    GROUP BY post.container_forum_id
),
comment_stats AS (
    SELECT forum.id AS forum_id,
           COUNT(comment.id) AS comment_count,
           AVG(comment.length) AS avg_comment_length
    FROM comment
    JOIN post ON comment.parent_post_id = post.id
    JOIN forum ON post.container_forum_id = forum.id
    GROUP BY forum.id
),
post_likes AS (
    SELECT forum.id AS forum_id,
           COUNT(person_likes_post.person_id) AS post_like_count
    FROM person_likes_post
    JOIN post ON person_likes_post.post_id = post.id
    JOIN forum ON post.container_forum_id = forum.id
    GROUP BY forum.id
),
comment_likes AS (
    SELECT forum.id AS forum_id,
           COUNT(person_likes_comment.person_id) AS comment_like_count
    FROM person_likes_comment
    JOIN comment ON person_likes_comment.comment_id = comment.id
    JOIN post ON comment.parent_post_id = post.id
    JOIN forum ON post.container_forum_id = forum.id
    GROUP BY forum.id
)
SELECT forum.id,
       forum.title,
       forum.creation_date,
       member_counts.member_count,
       member_interests.distinct_interest_tag_count,
       post_stats.post_count,
       post_stats.avg_post_length,
       post_likes.post_like_count,
       post_likes.post_like_count / NULLIF(post_stats.post_count, 0) AS avg_likes_per_post,
       comment_stats.comment_count,
       comment_stats.avg_comment_length,
       comment_likes.comment_like_count,
       comment_likes.comment_like_count / NULLIF(comment_stats.comment_count, 0) AS avg_likes_per_comment
FROM forum
LEFT JOIN member_counts ON member_counts.forum_id = forum.id
LEFT JOIN member_interests ON member_interests.forum_id = forum.id
LEFT JOIN post_stats ON post_stats.forum_id = forum.id
LEFT JOIN comment_stats ON comment_stats.forum_id = forum.id
LEFT JOIN post_likes ON post_likes.forum_id = forum.id
LEFT JOIN comment_likes ON comment_likes.forum_id = forum.id
ORDER BY forum.id
