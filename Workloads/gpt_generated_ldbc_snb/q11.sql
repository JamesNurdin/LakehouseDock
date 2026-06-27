WITH members_per_forum AS (
    SELECT fh.forum_id,
           COUNT(DISTINCT fh.person_id) AS member_count
    FROM forum_has_member_person fh
    GROUP BY fh.forum_id
),
posts_per_forum AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(*) AS post_count,
           AVG(p.length) AS avg_post_length
    FROM post p
    GROUP BY p.container_forum_id
),
likes_per_forum AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(*) AS total_likes
    FROM person_likes_post pl
    JOIN post p ON pl.post_id = p.id
    GROUP BY p.container_forum_id
)
SELECT f.id AS forum_id,
       f.title,
       mod.first_name,
       mod.last_name,
       COALESCE(m.member_count, 0) AS member_count,
       COALESCE(p.post_count, 0) AS post_count,
       COALESCE(p.avg_post_length, 0) AS avg_post_length,
       COALESCE(l.total_likes, 0) AS total_likes
FROM forum f
LEFT JOIN person mod ON f.moderator_person_id = mod.id
LEFT JOIN members_per_forum m ON f.id = m.forum_id
LEFT JOIN posts_per_forum p ON f.id = p.forum_id
LEFT JOIN likes_per_forum l ON f.id = l.forum_id
ORDER BY total_likes DESC
LIMIT 10
