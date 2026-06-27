WITH
    forum_mod AS (
        SELECT f.id AS forum_id,
               f.title,
               f.creation_date AS forum_creation_date,
               f.moderator_person_id,
               mod.first_name AS moderator_first_name,
               mod.last_name  AS moderator_last_name
        FROM forum f
        JOIN person mod
          ON f.moderator_person_id = mod.id
    ),
    forum_members AS (
        SELECT fhmp.forum_id,
               COUNT(DISTINCT fhmp.person_id) AS member_count
        FROM forum_has_member_person fhmp
        GROUP BY fhmp.forum_id
    ),
    forum_posts AS (
        SELECT p.container_forum_id AS forum_id,
               COUNT(*)               AS post_count,
               AVG(p.length)          AS avg_post_length
        FROM post p
        GROUP BY p.container_forum_id
    ),
    forum_comments AS (
        SELECT p.container_forum_id AS forum_id,
               COUNT(*)               AS comment_count
        FROM comment c
        JOIN post p
          ON c.parent_post_id = p.id
        GROUP BY p.container_forum_id
    ),
    forum_post_likes AS (
        SELECT p.container_forum_id AS forum_id,
               COUNT(*)               AS post_like_count
        FROM person_likes_post plp
        JOIN post p
          ON plp.post_id = p.id
        GROUP BY p.container_forum_id
    ),
    forum_comment_likes AS (
        SELECT p.container_forum_id AS forum_id,
               COUNT(*)               AS comment_like_count
        FROM person_likes_comment plc
        JOIN comment c
          ON plc.comment_id = c.id
        JOIN post p
          ON c.parent_post_id = p.id
        GROUP BY p.container_forum_id
    )
SELECT fm.forum_id,
       fm.title,
       fm.forum_creation_date,
       fm.moderator_first_name,
       fm.moderator_last_name,
       COALESCE(m.member_count, 0)            AS member_count,
       COALESCE(p.post_count, 0)              AS post_count,
       COALESCE(p.avg_post_length, 0)         AS avg_post_length,
       COALESCE(c.comment_count, 0)           AS comment_count,
       COALESCE(pl.post_like_count, 0)        AS post_like_count,
       COALESCE(cl.comment_like_count, 0)     AS comment_like_count,
       (COALESCE(p.post_count, 0) + COALESCE(c.comment_count, 0)) AS total_activity
FROM forum_mod fm
LEFT JOIN forum_members m
       ON fm.forum_id = m.forum_id
LEFT JOIN forum_posts p
       ON fm.forum_id = p.forum_id
LEFT JOIN forum_comments c
       ON fm.forum_id = c.forum_id
LEFT JOIN forum_post_likes pl
       ON fm.forum_id = pl.forum_id
LEFT JOIN forum_comment_likes cl
       ON fm.forum_id = cl.forum_id
ORDER BY total_activity DESC
LIMIT 10
