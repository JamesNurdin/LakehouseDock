WITH forum_members AS (
    SELECT
        forum.id AS forum_id,
        COUNT(DISTINCT forum_has_member_person.person_id) AS member_count
    FROM forum
    JOIN forum_has_member_person
        ON forum_has_member_person.forum_id = forum.id
    GROUP BY forum.id
),
forum_posts AS (
    SELECT
        forum.id AS forum_id,
        COUNT(DISTINCT post.id) AS post_count
    FROM forum
    JOIN post
        ON post.container_forum_id = forum.id
    GROUP BY forum.id
),
forum_comments AS (
    SELECT
        forum.id AS forum_id,
        COUNT(DISTINCT comment.id) AS comment_count,
        AVG(comment.length) AS avg_comment_length
    FROM forum
    JOIN post
        ON post.container_forum_id = forum.id
    JOIN comment
        ON comment.parent_post_id = post.id
    GROUP BY forum.id
),
forum_post_likes AS (
    SELECT
        forum.id AS forum_id,
        COUNT(*) AS post_like_count
    FROM forum
    JOIN post
        ON post.container_forum_id = forum.id
    JOIN person_likes_post
        ON person_likes_post.post_id = post.id
    GROUP BY forum.id
),
forum_comment_likes AS (
    SELECT
        forum.id AS forum_id,
        COUNT(*) AS comment_like_count
    FROM forum
    JOIN post
        ON post.container_forum_id = forum.id
    JOIN comment
        ON comment.parent_post_id = post.id
    JOIN person_likes_comment
        ON person_likes_comment.comment_id = comment.id
    GROUP BY forum.id
)
SELECT
    f.id AS forum_id,
    f.title AS forum_title,
    mod.first_name AS moderator_first_name,
    mod.last_name AS moderator_last_name,
    COALESCE(m.member_count, 0) AS member_count,
    COALESCE(p.post_count, 0) AS post_count,
    COALESCE(c.comment_count, 0) AS comment_count,
    COALESCE(c.avg_comment_length, 0) AS avg_comment_length,
    COALESCE(pl.post_like_count, 0) AS post_like_count,
    COALESCE(cl.comment_like_count, 0) AS comment_like_count,
    ROW_NUMBER() OVER (ORDER BY COALESCE(c.comment_count, 0) DESC) AS forum_rank_by_comments
FROM forum AS f
LEFT JOIN person AS mod
    ON mod.id = f.moderator_person_id
LEFT JOIN forum_members AS m
    ON m.forum_id = f.id
LEFT JOIN forum_posts AS p
    ON p.forum_id = f.id
LEFT JOIN forum_comments AS c
    ON c.forum_id = f.id
LEFT JOIN forum_post_likes AS pl
    ON pl.forum_id = f.id
LEFT JOIN forum_comment_likes AS cl
    ON cl.forum_id = f.id
ORDER BY forum_rank_by_comments
