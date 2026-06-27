WITH forum_members AS (
        SELECT f.id AS forum_id,
               COUNT(DISTINCT fm.person_id) AS member_count
        FROM forum f
        JOIN forum_has_member_person fm
          ON fm.forum_id = f.id
        GROUP BY f.id
    ),
    forum_posts AS (
        SELECT f.id AS forum_id,
               COUNT(p.id) AS post_count,
               SUM(p.length) AS total_post_length,
               AVG(p.length) AS avg_post_length
        FROM forum f
        JOIN post p
          ON p.container_forum_id = f.id
        GROUP BY f.id
    ),
    forum_comments AS (
        SELECT f.id AS forum_id,
               COUNT(c.id) AS comment_count,
               SUM(c.length) AS total_comment_length,
               AVG(c.length) AS avg_comment_length
        FROM forum f
        JOIN post p
          ON p.container_forum_id = f.id
        JOIN comment c
          ON c.parent_post_id = p.id
        GROUP BY f.id
    ),
    forum_post_likes AS (
        SELECT f.id AS forum_id,
               COUNT(pl.person_id) AS post_like_count
        FROM forum f
        JOIN post p
          ON p.container_forum_id = f.id
        JOIN person_likes_post pl
          ON pl.post_id = p.id
        GROUP BY f.id
    ),
    forum_comment_likes AS (
        SELECT f.id AS forum_id,
               COUNT(cl.person_id) AS comment_like_count
        FROM forum f
        JOIN post p
          ON p.container_forum_id = f.id
        JOIN comment c
          ON c.parent_post_id = p.id
        JOIN person_likes_comment cl
          ON cl.comment_id = c.id
        GROUP BY f.id
    )
SELECT f.id,
       f.title,
       f.creation_date,
       COALESCE(m.member_count, 0)          AS member_count,
       COALESCE(p.post_count, 0)            AS post_count,
       COALESCE(p.total_post_length, 0)     AS total_post_length,
       COALESCE(p.avg_post_length, 0)       AS avg_post_length,
       COALESCE(c.comment_count, 0)         AS comment_count,
       COALESCE(c.total_comment_length, 0)  AS total_comment_length,
       COALESCE(c.avg_comment_length, 0)    AS avg_comment_length,
       COALESCE(pl.post_like_count, 0)      AS post_like_count,
       COALESCE(cl.comment_like_count, 0)   AS comment_like_count
FROM forum f
LEFT JOIN forum_members m
       ON m.forum_id = f.id
LEFT JOIN forum_posts p
       ON p.forum_id = f.id
LEFT JOIN forum_comments c
       ON c.forum_id = f.id
LEFT JOIN forum_post_likes pl
       ON pl.forum_id = f.id
LEFT JOIN forum_comment_likes cl
       ON cl.forum_id = f.id
ORDER BY f.id
