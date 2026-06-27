WITH forum_members AS (
    SELECT fm.forum_id,
           COUNT(DISTINCT fm.person_id) AS member_count
    FROM forum_has_member_person fm
    GROUP BY fm.forum_id
),
forum_posts AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(*) AS post_count
    FROM post p
    GROUP BY p.container_forum_id
),
forum_comments AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(*) AS comment_count,
           AVG(c.length) AS avg_comment_length
    FROM comment c
    JOIN post p ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
),
post_likes AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(*) AS total_post_likes
    FROM person_likes_post plp
    JOIN post p ON plp.post_id = p.id
    GROUP BY p.container_forum_id
),
comment_likes AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(*) AS total_comment_likes
    FROM person_likes_comment plc
    JOIN comment c ON plc.comment_id = c.id
    JOIN post p ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
)
SELECT
    f.id AS forum_id,
    f.title AS forum_title,
    COALESCE(fm.member_count, 0) AS member_count,
    COALESCE(fp.post_count, 0) AS post_count,
    COALESCE(fc.comment_count, 0) AS comment_count,
    COALESCE(pl.total_post_likes, 0) AS total_post_likes,
    COALESCE(cl.total_comment_likes, 0) AS total_comment_likes,
    fc.avg_comment_length
FROM forum f
LEFT JOIN forum_members fm ON fm.forum_id = f.id
LEFT JOIN forum_posts fp ON fp.forum_id = f.id
LEFT JOIN forum_comments fc ON fc.forum_id = f.id
LEFT JOIN post_likes pl ON pl.forum_id = f.id
LEFT JOIN comment_likes cl ON cl.forum_id = f.id
ORDER BY (COALESCE(pl.total_post_likes, 0) + COALESCE(cl.total_comment_likes, 0)) DESC
LIMIT 10
