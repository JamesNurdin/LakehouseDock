WITH forum_members AS (
    SELECT f.id AS forum_id,
           COUNT(DISTINCT fm.person_id) AS member_count
    FROM forum_has_member_person fm
    JOIN forum f ON fm.forum_id = f.id
    GROUP BY f.id
),
forum_tags AS (
    SELECT f.id AS forum_id,
           COUNT(DISTINCT ft.tag_id) AS tag_count
    FROM forum_has_tag_tag ft
    JOIN forum f ON ft.forum_id = f.id
    GROUP BY f.id
),
forum_posts AS (
    SELECT f.id AS forum_id,
           COUNT(DISTINCT p.id) AS post_count,
           AVG(p.length) AS avg_post_length
    FROM post p
    JOIN forum f ON p.container_forum_id = f.id
    GROUP BY f.id
),
post_likes AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(DISTINCT pl.person_id) AS total_likes
    FROM person_likes_post pl
    JOIN post p ON pl.post_id = p.id
    GROUP BY p.container_forum_id
),
forum_moderator AS (
    SELECT f.id AS forum_id,
           mod.first_name AS moderator_first_name,
           mod.last_name AS moderator_last_name
    FROM forum f
    JOIN person mod ON f.moderator_person_id = mod.id
)
SELECT f.title,
       fm.moderator_first_name,
       fm.moderator_last_name,
       COALESCE(m.member_count, 0) AS member_count,
       COALESCE(p.post_count, 0) AS post_count,
       COALESCE(p.avg_post_length, 0) AS avg_post_length,
       COALESCE(l.total_likes, 0) AS total_likes,
       COALESCE(t.tag_count, 0) AS tag_count
FROM forum f
LEFT JOIN forum_moderator fm ON f.id = fm.forum_id
LEFT JOIN forum_members m ON f.id = m.forum_id
LEFT JOIN forum_tags t ON f.id = t.forum_id
LEFT JOIN forum_posts p ON f.id = p.forum_id
LEFT JOIN post_likes l ON f.id = l.forum_id
ORDER BY total_likes DESC
LIMIT 5
