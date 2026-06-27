WITH
forum_base AS (
    SELECT id, title, creation_date
    FROM forum
),
post_stats AS (
    SELECT f.id AS forum_id,
           COUNT(p.id) AS num_posts,
           SUM(p.length) AS total_post_length,
           AVG(p.length) AS avg_post_length
    FROM forum f
    JOIN post p ON p.container_forum_id = f.id
    GROUP BY f.id
),
member_stats AS (
    SELECT f.id AS forum_id,
           COUNT(DISTINCT fm.person_id) AS num_members
    FROM forum f
    JOIN forum_has_member_person fm ON fm.forum_id = f.id
    GROUP BY f.id
),
comment_stats AS (
    SELECT f.id AS forum_id,
           COUNT(c.id) AS num_comments
    FROM forum f
    JOIN post p ON p.container_forum_id = f.id
    JOIN comment c ON c.parent_post_id = p.id
    GROUP BY f.id
),
like_stats AS (
    SELECT f.id AS forum_id,
           COUNT(plp.person_id) AS total_likes
    FROM forum f
    JOIN post p ON p.container_forum_id = f.id
    JOIN person_likes_post plp ON plp.post_id = p.id
    GROUP BY f.id
),
moderator_info AS (
    SELECT f.id AS forum_id,
           p.first_name AS moderator_first_name,
           p.last_name AS moderator_last_name
    FROM forum f
    JOIN person p ON f.moderator_person_id = p.id
)

SELECT b.id,
       b.title,
       b.creation_date,
       mi.moderator_first_name,
       mi.moderator_last_name,
       COALESCE(p.num_posts, 0) AS num_posts,
       COALESCE(p.total_post_length, 0) AS total_post_length,
       COALESCE(p.avg_post_length, 0) AS avg_post_length,
       COALESCE(m.num_members, 0) AS num_members,
       COALESCE(c.num_comments, 0) AS num_comments,
       COALESCE(l.total_likes, 0) AS total_likes
FROM forum_base b
LEFT JOIN post_stats p ON p.forum_id = b.id
LEFT JOIN member_stats m ON m.forum_id = b.id
LEFT JOIN comment_stats c ON c.forum_id = b.id
LEFT JOIN like_stats l ON l.forum_id = b.id
LEFT JOIN moderator_info mi ON mi.forum_id = b.id
ORDER BY b.id
