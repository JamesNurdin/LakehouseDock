WITH forum_members AS (
        SELECT f.id AS forum_id,
               COUNT(DISTINCT fm.person_id) AS member_count
        FROM forum f
        JOIN forum_has_member_person fm ON fm.forum_id = f.id
        GROUP BY f.id
    ),
    forum_posts AS (
        SELECT f.id AS forum_id,
               COUNT(p.id) AS post_count
        FROM forum f
        JOIN post p ON p.container_forum_id = f.id
        GROUP BY f.id
    ),
    forum_comments AS (
        SELECT f.id AS forum_id,
               COUNT(c.id) AS comment_count
        FROM forum f
        JOIN post p ON p.container_forum_id = f.id
        JOIN comment c ON c.parent_post_id = p.id
        GROUP BY f.id
    ),
    forum_post_likes AS (
        SELECT f.id AS forum_id,
               COUNT(pl.person_id) AS post_like_count
        FROM forum f
        JOIN post p ON p.container_forum_id = f.id
        JOIN person_likes_post pl ON pl.post_id = p.id
        GROUP BY f.id
    ),
    forum_comment_likes AS (
        SELECT f.id AS forum_id,
               COUNT(cl.person_id) AS comment_like_count
        FROM forum f
        JOIN post p ON p.container_forum_id = f.id
        JOIN comment c ON c.parent_post_id = p.id
        JOIN person_likes_comment cl ON cl.comment_id = c.id
        GROUP BY f.id
    )
SELECT f.id,
       f.title,
       COALESCE(m.member_count, 0)               AS member_count,
       COALESCE(p.post_count, 0)                 AS post_count,
       COALESCE(c.comment_count, 0)              AS comment_count,
       COALESCE(pl.post_like_count, 0)           AS post_like_count,
       COALESCE(cl.comment_like_count, 0)        AS comment_like_count,
       CASE WHEN COALESCE(p.post_count, 0) > 0
            THEN COALESCE(pl.post_like_count, 0) * 1.0 / p.post_count
            ELSE 0 END                         AS avg_likes_per_post,
       CASE WHEN COALESCE(c.comment_count, 0) > 0
            THEN COALESCE(cl.comment_like_count, 0) * 1.0 / c.comment_count
            ELSE 0 END                         AS avg_likes_per_comment
FROM forum f
LEFT JOIN forum_members m        ON m.forum_id = f.id
LEFT JOIN forum_posts p          ON p.forum_id = f.id
LEFT JOIN forum_comments c       ON c.forum_id = f.id
LEFT JOIN forum_post_likes pl    ON pl.forum_id = f.id
LEFT JOIN forum_comment_likes cl ON cl.forum_id = f.id
ORDER BY (COALESCE(p.post_count, 0) + COALESCE(c.comment_count, 0)) DESC
LIMIT 10
