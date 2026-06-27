-- Top 10 most active forums with various activity metrics
WITH forum_base AS (
    SELECT f.id AS forum_id,
           f.title,
           mod.id AS moderator_id,
           mod.first_name AS moderator_first_name,
           mod.last_name AS moderator_last_name
    FROM forum f
    LEFT JOIN person mod ON f.moderator_person_id = mod.id
),
member_counts AS (
    SELECT fm.forum_id,
           COUNT(DISTINCT fm.person_id) AS member_count
    FROM forum_has_member_person fm
    GROUP BY fm.forum_id
),
post_metrics AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(DISTINCT p.id) AS post_count,
           AVG(p.length) AS avg_post_length
    FROM post p
    GROUP BY p.container_forum_id
),
comment_metrics AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(DISTINCT c.id) AS comment_count,
           AVG(c.length) AS avg_comment_length
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
),
post_tag_counts AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(DISTINCT pt.tag_id) AS distinct_post_tag_count
    FROM post_has_tag_tag pt
    JOIN post p ON pt.post_id = p.id
    GROUP BY p.container_forum_id
),
forum_tag_counts AS (
    SELECT ft.forum_id,
           COUNT(DISTINCT ft.tag_id) AS distinct_forum_tag_count
    FROM forum_has_tag_tag ft
    GROUP BY ft.forum_id
)
SELECT fb.forum_id,
       fb.title,
       fb.moderator_first_name,
       fb.moderator_last_name,
       COALESCE(mc.member_count, 0)               AS member_count,
       COALESCE(pm.post_count, 0)                 AS post_count,
       COALESCE(pm.avg_post_length, 0)            AS avg_post_length,
       COALESCE(cm.comment_count, 0)              AS comment_count,
       COALESCE(cm.avg_comment_length, 0)         AS avg_comment_length,
       COALESCE(plc.post_like_count, 0)           AS post_like_count,
       COALESCE(clc.comment_like_count, 0)        AS comment_like_count,
       COALESCE(ptc.distinct_post_tag_count, 0)   AS distinct_post_tag_count,
       COALESCE(ftc.distinct_forum_tag_count, 0)  AS distinct_forum_tag_count,
       (COALESCE(pm.post_count, 0) + COALESCE(cm.comment_count, 0) +
        COALESCE(plc.post_like_count, 0) + COALESCE(clc.comment_like_count, 0)) AS total_activity
FROM forum_base fb
LEFT JOIN member_counts mc          ON fb.forum_id = mc.forum_id
LEFT JOIN post_metrics pm           ON fb.forum_id = pm.forum_id
LEFT JOIN comment_metrics cm        ON fb.forum_id = cm.forum_id
LEFT JOIN post_like_counts plc      ON fb.forum_id = plc.forum_id
LEFT JOIN comment_like_counts clc   ON fb.forum_id = clc.forum_id
LEFT JOIN post_tag_counts ptc       ON fb.forum_id = ptc.forum_id
LEFT JOIN forum_tag_counts ftc      ON fb.forum_id = ftc.forum_id
ORDER BY total_activity DESC
LIMIT 10
