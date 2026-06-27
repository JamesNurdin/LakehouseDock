WITH post_likes AS (
    SELECT post_id,
           COUNT(*) AS like_count
    FROM person_likes_post
    GROUP BY post_id
),
comment_likes AS (
    SELECT comment_id,
           COUNT(*) AS like_count
    FROM person_likes_comment
    GROUP BY comment_id
),
forum_stats AS (
    SELECT
        f.id AS forum_id,
        f.title,
        f.creation_date,
        COUNT(DISTINCT p.id) AS post_count,
        COUNT(DISTINCT c.id) AS comment_count,
        COALESCE(SUM(pl.like_count), 0) AS total_post_likes,
        COALESCE(SUM(cl.like_count), 0) AS total_comment_likes,
        AVG(p.length) AS avg_post_length,
        AVG(c.length) AS avg_comment_length,
        COUNT(DISTINCT fm.person_id) AS member_count
    FROM forum f
    LEFT JOIN post p
        ON p.container_forum_id = f.id
    LEFT JOIN comment c
        ON c.parent_post_id = p.id
    LEFT JOIN post_likes pl
        ON pl.post_id = p.id
    LEFT JOIN comment_likes cl
        ON cl.comment_id = c.id
    LEFT JOIN forum_has_member_person fm
        ON fm.forum_id = f.id
    GROUP BY f.id, f.title, f.creation_date
)
SELECT
    forum_id,
    title,
    creation_date,
    post_count,
    comment_count,
    total_post_likes,
    total_comment_likes,
    avg_post_length,
    avg_comment_length,
    member_count
FROM forum_stats
ORDER BY post_count DESC
LIMIT 10
