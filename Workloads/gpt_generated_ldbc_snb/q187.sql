WITH post_counts AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(*) AS post_count
    FROM post p
    GROUP BY p.container_forum_id
),
post_likes AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(pl.person_id) AS post_likes
    FROM post p
    LEFT JOIN person_likes_post pl ON p.id = pl.post_id
    GROUP BY p.container_forum_id
),
comment_counts AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(*) AS comment_count
    FROM comment c
    JOIN post p ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
),
comment_likes AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(cl.person_id) AS comment_likes
    FROM comment c
    JOIN post p ON c.parent_post_id = p.id
    LEFT JOIN person_likes_comment cl ON c.id = cl.comment_id
    GROUP BY p.container_forum_id
),
forum_members AS (
    SELECT fm.forum_id,
           COUNT(DISTINCT fm.person_id) AS member_count
    FROM forum_has_member_person fm
    GROUP BY fm.forum_id
)
SELECT f.id AS forum_id,
       f.title AS forum_title,
       mod.first_name || ' ' || mod.last_name AS moderator_name,
       COALESCE(pc.post_count, 0) AS post_count,
       COALESCE(pl.post_likes, 0) AS post_likes,
       COALESCE(cc.comment_count, 0) AS comment_count,
       COALESCE(cl.comment_likes, 0) AS comment_likes,
       COALESCE(m.member_count, 0) AS member_count,
       (COALESCE(pl.post_likes, 0) + COALESCE(cl.comment_likes, 0)) AS total_likes
FROM forum f
LEFT JOIN person mod ON f.moderator_person_id = mod.id
LEFT JOIN post_counts pc ON f.id = pc.forum_id
LEFT JOIN post_likes pl ON f.id = pl.forum_id
LEFT JOIN comment_counts cc ON f.id = cc.forum_id
LEFT JOIN comment_likes cl ON f.id = cl.forum_id
LEFT JOIN forum_members m ON f.id = m.forum_id
ORDER BY total_likes DESC
LIMIT 10
