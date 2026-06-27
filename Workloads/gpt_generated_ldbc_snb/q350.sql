WITH forum_info AS (
    SELECT f.id AS forum_id,
           f.title,
           m.first_name AS moderator_first_name,
           m.last_name  AS moderator_last_name
    FROM forum AS f
    LEFT JOIN person AS m
        ON f.moderator_person_id = m.id
),
post_stats AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(DISTINCT p.id)   AS post_count,
           AVG(p.length)          AS avg_post_length
    FROM post AS p
    GROUP BY p.container_forum_id
),
comment_stats AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(DISTINCT c.id)   AS comment_count,
           AVG(c.length)          AS avg_comment_length
    FROM comment AS c
    JOIN post AS p
        ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
),
post_likes AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(*)               AS post_like_count
    FROM person_likes_post AS plp
    JOIN post AS p
        ON plp.post_id = p.id
    GROUP BY p.container_forum_id
),
comment_likes AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(*)               AS comment_like_count
    FROM person_likes_comment AS plc
    JOIN comment AS c
        ON plc.comment_id = c.id
    JOIN post AS p
        ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
),
member_counts AS (
    SELECT fhmp.forum_id,
           COUNT(DISTINCT fhmp.person_id) AS member_count
    FROM forum_has_member_person AS fhmp
    GROUP BY fhmp.forum_id
)
SELECT fi.forum_id,
       fi.title,
       fi.moderator_first_name,
       fi.moderator_last_name,
       COALESCE(ps.post_count, 0)            AS post_count,
       COALESCE(cs.comment_count, 0)         AS comment_count,
       COALESCE(pl.post_like_count, 0)       AS post_like_count,
       COALESCE(cl.comment_like_count, 0)    AS comment_like_count,
       COALESCE(ps.avg_post_length, 0)       AS avg_post_length,
       COALESCE(cs.avg_comment_length, 0)    AS avg_comment_length,
       COALESCE(mc.member_count, 0)          AS member_count,
       (COALESCE(ps.post_count, 0) + COALESCE(cs.comment_count, 0)) AS total_activity
FROM forum_info      AS fi
LEFT JOIN post_stats     AS ps ON fi.forum_id = ps.forum_id
LEFT JOIN comment_stats  AS cs ON fi.forum_id = cs.forum_id
LEFT JOIN post_likes     AS pl ON fi.forum_id = pl.forum_id
LEFT JOIN comment_likes  AS cl ON fi.forum_id = cl.forum_id
LEFT JOIN member_counts  AS mc ON fi.forum_id = mc.forum_id
ORDER BY total_activity DESC
LIMIT 10
