WITH forum_base AS (
    SELECT f.id AS forum_id,
           f.title AS forum_title
    FROM forum f
),
moderator_info AS (
    SELECT f.id AS forum_id,
           p.first_name AS moderator_first_name,
           p.last_name AS moderator_last_name
    FROM forum f
    JOIN person p ON f.moderator_person_id = p.id
),
member_counts AS (
    SELECT fm.forum_id,
           COUNT(DISTINCT fm.person_id) AS member_count
    FROM forum_has_member_person fm
    GROUP BY fm.forum_id
),
post_stats AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(*) AS post_count,
           AVG(p.length) AS avg_post_length
    FROM post p
    GROUP BY p.container_forum_id
),
comment_stats AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(*) AS comment_count,
           AVG(c.length) AS avg_comment_length
    FROM comment c
    JOIN post p ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
),
comment_like_counts AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(*) AS comment_like_count
    FROM person_likes_comment plc
    JOIN comment c ON plc.comment_id = c.id
    JOIN post p ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
)
SELECT fb.forum_id,
       fb.forum_title,
       COALESCE(mi.moderator_first_name, '') AS moderator_first_name,
       COALESCE(mi.moderator_last_name, '') AS moderator_last_name,
       COALESCE(mc.member_count, 0) AS member_count,
       COALESCE(ps.post_count, 0) AS post_count,
       COALESCE(ps.avg_post_length, 0) AS avg_post_length,
       COALESCE(cs.comment_count, 0) AS comment_count,
       COALESCE(cs.avg_comment_length, 0) AS avg_comment_length,
       COALESCE(clc.comment_like_count, 0) AS comment_like_count
FROM forum_base fb
LEFT JOIN moderator_info mi ON fb.forum_id = mi.forum_id
LEFT JOIN member_counts mc ON fb.forum_id = mc.forum_id
LEFT JOIN post_stats ps ON fb.forum_id = ps.forum_id
LEFT JOIN comment_stats cs ON fb.forum_id = cs.forum_id
LEFT JOIN comment_like_counts clc ON fb.forum_id = clc.forum_id
ORDER BY fb.forum_id
