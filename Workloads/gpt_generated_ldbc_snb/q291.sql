WITH forum_members AS (
    SELECT
        forum_has_member_person.forum_id,
        COUNT(DISTINCT forum_has_member_person.person_id) AS member_count
    FROM forum_has_member_person
    GROUP BY forum_has_member_person.forum_id
),
forum_posts AS (
    SELECT
        post.container_forum_id AS forum_id,
        COUNT(*) AS post_count
    FROM post
    GROUP BY post.container_forum_id
),
forum_comments AS (
    SELECT
        post.container_forum_id AS forum_id,
        COUNT(comment.id) AS comment_count,
        AVG(comment.length) AS avg_comment_length
    FROM comment
    JOIN post ON comment.parent_post_id = post.id
    GROUP BY post.container_forum_id
),
forum_comment_likes AS (
    SELECT
        post.container_forum_id AS forum_id,
        COUNT(person_likes_comment.person_id) AS comment_like_count,
        COUNT(DISTINCT person_likes_comment.person_id) AS distinct_comment_likers
    FROM person_likes_comment
    JOIN comment ON person_likes_comment.comment_id = comment.id
    JOIN post ON comment.parent_post_id = post.id
    GROUP BY post.container_forum_id
),
forum_post_likes AS (
    SELECT
        post.container_forum_id AS forum_id,
        COUNT(person_likes_post.person_id) AS post_like_count,
        COUNT(DISTINCT person_likes_post.person_id) AS distinct_post_likers
    FROM person_likes_post
    JOIN post ON person_likes_post.post_id = post.id
    GROUP BY post.container_forum_id
),
forum_moderator AS (
    SELECT
        forum.id AS forum_id,
        person.first_name AS moderator_first_name,
        person.last_name AS moderator_last_name
    FROM forum
    JOIN person ON forum.moderator_person_id = person.id
),
forum_comment_tags AS (
    SELECT
        post.container_forum_id AS forum_id,
        COUNT(DISTINCT comment_has_tag_tag.tag_id) AS distinct_tag_count
    FROM comment_has_tag_tag
    JOIN comment ON comment_has_tag_tag.comment_id = comment.id
    JOIN post ON comment.parent_post_id = post.id
    GROUP BY post.container_forum_id
)
SELECT
    forum.id AS forum_id,
    forum.title AS forum_title,
    COALESCE(forum_members.member_count, 0) AS member_count,
    COALESCE(forum_posts.post_count, 0) AS post_count,
    COALESCE(forum_comments.comment_count, 0) AS comment_count,
    COALESCE(forum_comments.avg_comment_length, 0) AS avg_comment_length,
    COALESCE(forum_comment_likes.comment_like_count, 0) AS comment_like_count,
    COALESCE(forum_comment_likes.distinct_comment_likers, 0) AS distinct_comment_likers,
    COALESCE(forum_post_likes.post_like_count, 0) AS post_like_count,
    COALESCE(forum_post_likes.distinct_post_likers, 0) AS distinct_post_likers,
    COALESCE(forum_comment_tags.distinct_tag_count, 0) AS distinct_tag_count,
    forum_moderator.moderator_first_name,
    forum_moderator.moderator_last_name
FROM forum
LEFT JOIN forum_members ON forum.id = forum_members.forum_id
LEFT JOIN forum_posts ON forum.id = forum_posts.forum_id
LEFT JOIN forum_comments ON forum.id = forum_comments.forum_id
LEFT JOIN forum_comment_likes ON forum.id = forum_comment_likes.forum_id
LEFT JOIN forum_post_likes ON forum.id = forum_post_likes.forum_id
LEFT JOIN forum_comment_tags ON forum.id = forum_comment_tags.forum_id
LEFT JOIN forum_moderator ON forum.id = forum_moderator.forum_id
ORDER BY comment_count DESC
LIMIT 10
