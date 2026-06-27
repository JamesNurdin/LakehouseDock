WITH
    forum_posts AS (
        SELECT
            forum.id AS forum_id,
            COUNT(post.id) AS post_count,
            AVG(post.length) AS avg_post_length
        FROM forum
        JOIN post ON post.container_forum_id = forum.id
        GROUP BY forum.id
    ),
    forum_comments AS (
        SELECT
            forum.id AS forum_id,
            COUNT(comment.id) AS comment_count,
            AVG(comment.length) AS avg_comment_length
        FROM forum
        JOIN post ON post.container_forum_id = forum.id
        JOIN comment ON comment.parent_post_id = post.id
        GROUP BY forum.id
    ),
    forum_post_likes AS (
        SELECT
            forum.id AS forum_id,
            COUNT(person_likes_post.person_id) AS post_like_count
        FROM forum
        JOIN post ON post.container_forum_id = forum.id
        JOIN person_likes_post ON person_likes_post.post_id = post.id
        GROUP BY forum.id
    ),
    forum_comment_likes AS (
        SELECT
            forum.id AS forum_id,
            COUNT(person_likes_comment.person_id) AS comment_like_count
        FROM forum
        JOIN post ON post.container_forum_id = forum.id
        JOIN comment ON comment.parent_post_id = post.id
        JOIN person_likes_comment ON person_likes_comment.comment_id = comment.id
        GROUP BY forum.id
    ),
    forum_members AS (
        SELECT
            forum.id AS forum_id,
            COUNT(forum_has_member_person.person_id) AS member_count
        FROM forum
        JOIN forum_has_member_person ON forum_has_member_person.forum_id = forum.id
        GROUP BY forum.id
    ),
    forum_tags AS (
        SELECT
            forum.id AS forum_id,
            COUNT(forum_has_tag_tag.tag_id) AS tag_count
        FROM forum
        JOIN forum_has_tag_tag ON forum_has_tag_tag.forum_id = forum.id
        GROUP BY forum.id
    ),
    gender_rows AS (
        SELECT
            forum.id AS forum_id,
            person.gender AS gender
        FROM forum
        JOIN post ON post.container_forum_id = forum.id
        JOIN person ON post.creator_person_id = person.id
        UNION ALL
        SELECT
            forum.id AS forum_id,
            person.gender AS gender
        FROM forum
        JOIN post ON post.container_forum_id = forum.id
        JOIN comment ON comment.parent_post_id = post.id
        JOIN person ON comment.creator_person_id = person.id
    ),
    forum_creator_genders AS (
        SELECT
            forum_id,
            COUNT(DISTINCT gender) AS distinct_creator_genders
        FROM gender_rows
        GROUP BY forum_id
    )
SELECT
    f.id AS forum_id,
    f.title,
    f.creation_date,
    COALESCE(p.post_count, 0) AS total_posts,
    COALESCE(c.comment_count, 0) AS total_comments,
    COALESCE(pl.post_like_count, 0) AS total_post_likes,
    COALESCE(cl.comment_like_count, 0) AS total_comment_likes,
    (COALESCE(p.post_count, 0) + COALESCE(c.comment_count, 0) + COALESCE(pl.post_like_count, 0) + COALESCE(cl.comment_like_count, 0)) AS total_engagement,
    p.avg_post_length,
    c.avg_comment_length,
    COALESCE(m.member_count, 0) AS member_count,
    COALESCE(t.tag_count, 0) AS tag_count,
    COALESCE(g.distinct_creator_genders, 0) AS distinct_creator_genders
FROM forum AS f
LEFT JOIN forum_posts AS p ON p.forum_id = f.id
LEFT JOIN forum_comments AS c ON c.forum_id = f.id
LEFT JOIN forum_post_likes AS pl ON pl.forum_id = f.id
LEFT JOIN forum_comment_likes AS cl ON cl.forum_id = f.id
LEFT JOIN forum_members AS m ON m.forum_id = f.id
LEFT JOIN forum_tags AS t ON t.forum_id = f.id
LEFT JOIN forum_creator_genders AS g ON g.forum_id = f.id
ORDER BY total_engagement DESC
LIMIT 10
