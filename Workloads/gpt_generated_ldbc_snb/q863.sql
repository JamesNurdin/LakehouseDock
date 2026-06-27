WITH member_counts AS (
    SELECT fm.forum_id,
           COUNT(DISTINCT fm.person_id) AS member_count
    FROM forum_has_member_person fm
    GROUP BY fm.forum_id
),
post_counts AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(*) AS post_count
    FROM post p
    GROUP BY p.container_forum_id
),
comment_counts AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(*) AS comment_count
    FROM comment c
    JOIN post p ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
),
post_like_counts AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(*) AS post_like_count
    FROM person_likes_post plp
    JOIN post p ON plp.post_id = p.id
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
SELECT f.id,
       f.title,
       COALESCE(m.member_count, 0) AS member_count,
       COALESCE(pc.post_count, 0) AS post_count,
       COALESCE(cc.comment_count, 0) AS comment_count,
       COALESCE(plc.post_like_count, 0) AS post_like_count,
       COALESCE(clc.comment_like_count, 0) AS comment_like_count,
       (COALESCE(m.member_count, 0) + COALESCE(pc.post_count, 0) + COALESCE(cc.comment_count, 0) + COALESCE(plc.post_like_count, 0) + COALESCE(clc.comment_like_count, 0)) AS total_activity
FROM forum f
LEFT JOIN member_counts m   ON f.id = m.forum_id
LEFT JOIN post_counts pc    ON f.id = pc.forum_id
LEFT JOIN comment_counts cc ON f.id = cc.forum_id
LEFT JOIN post_like_counts plc ON f.id = plc.forum_id
LEFT JOIN comment_like_counts clc ON f.id = clc.forum_id
ORDER BY total_activity DESC
LIMIT 10
