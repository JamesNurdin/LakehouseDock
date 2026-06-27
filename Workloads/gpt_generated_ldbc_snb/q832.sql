WITH forum_base AS (
    SELECT forum.id,
           forum.title
    FROM forum
),
forum_members AS (
    SELECT forum_has_member_person.forum_id,
           COUNT(DISTINCT forum_has_member_person.person_id) AS member_count
    FROM forum_has_member_person
    GROUP BY forum_has_member_person.forum_id
),
forum_tags AS (
    SELECT forum_has_tag_tag.forum_id,
           COUNT(DISTINCT forum_has_tag_tag.tag_id) AS tag_count
    FROM forum_has_tag_tag
    GROUP BY forum_has_tag_tag.forum_id
),
forum_posts AS (
    SELECT post.container_forum_id AS forum_id,
           COUNT(DISTINCT post.id) AS post_count,
           SUM(post.length) AS total_post_length
    FROM post
    GROUP BY post.container_forum_id
),
forum_comments AS (
    SELECT post.container_forum_id AS forum_id,
           COUNT(DISTINCT comment.id) AS comment_count
    FROM comment
    JOIN post ON comment.parent_post_id = post.id
    GROUP BY post.container_forum_id
),
forum_comment_likers AS (
    SELECT post.container_forum_id AS forum_id,
           COUNT(DISTINCT person_likes_comment.person_id) AS comment_liker_count
    FROM comment
    JOIN post ON comment.parent_post_id = post.id
    JOIN person_likes_comment ON person_likes_comment.comment_id = comment.id
    GROUP BY post.container_forum_id
)
SELECT
    fb.id AS forum_id,
    fb.title AS forum_title,
    COALESCE(fp.post_count, 0) AS post_count,
    CASE WHEN COALESCE(fp.post_count, 0) = 0 THEN NULL
         ELSE fp.total_post_length / fp.post_count END AS avg_post_length,
    COALESCE(fc.comment_count, 0) AS comment_count,
    COALESCE(fm.member_count, 0) AS member_count,
    COALESCE(ft.tag_count, 0) AS tag_count,
    COALESCE(fcl.comment_liker_count, 0) AS comment_liker_count
FROM forum_base fb
LEFT JOIN forum_members fm ON fb.id = fm.forum_id
LEFT JOIN forum_tags ft ON fb.id = ft.forum_id
LEFT JOIN forum_posts fp ON fb.id = fp.forum_id
LEFT JOIN forum_comments fc ON fb.id = fc.forum_id
LEFT JOIN forum_comment_likers fcl ON fb.id = fcl.forum_id
ORDER BY post_count DESC
LIMIT 10
