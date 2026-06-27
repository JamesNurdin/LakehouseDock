WITH forum_base AS (
    SELECT f.id AS forum_id,
           f.title,
           f.creation_date,
           f.moderator_person_id
    FROM forum f
),
moderator_info AS (
    SELECT p.id AS person_id,
           p.first_name,
           p.last_name
    FROM person p
),
posts_agg AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(*) AS total_posts
    FROM post p
    GROUP BY p.container_forum_id
),
comments_agg AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(*) AS total_comments,
           AVG(c.length) AS avg_comment_length
    FROM comment c
    JOIN post p ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
),
likes_agg AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(*) AS total_likes
    FROM person_likes_post pl
    JOIN post p ON pl.post_id = p.id
    GROUP BY p.container_forum_id
),
participants_agg AS (
    SELECT forum_id,
           COUNT(DISTINCT person_id) AS unique_participants
    FROM (
        SELECT p.container_forum_id AS forum_id,
               p.creator_person_id AS person_id
        FROM post p
        UNION ALL
        SELECT p.container_forum_id AS forum_id,
               c.creator_person_id AS person_id
        FROM comment c
        JOIN post p ON c.parent_post_id = p.id
        UNION ALL
        SELECT p.container_forum_id AS forum_id,
               pl.person_id AS person_id
        FROM person_likes_post pl
        JOIN post p ON pl.post_id = p.id
    ) sub
    GROUP BY forum_id
)
SELECT fb.forum_id,
       fb.title,
       fb.creation_date,
       mi.first_name AS moderator_first_name,
       mi.last_name AS moderator_last_name,
       COALESCE(pa.total_posts, 0) AS total_posts,
       COALESCE(ca.total_comments, 0) AS total_comments,
       COALESCE(la.total_likes, 0) AS total_likes,
       ca.avg_comment_length,
       COALESCE(pa2.unique_participants, 0) AS unique_participants
FROM forum_base fb
LEFT JOIN moderator_info mi ON fb.moderator_person_id = mi.person_id
LEFT JOIN posts_agg pa ON fb.forum_id = pa.forum_id
LEFT JOIN comments_agg ca ON fb.forum_id = ca.forum_id
LEFT JOIN likes_agg la ON fb.forum_id = la.forum_id
LEFT JOIN participants_agg pa2 ON fb.forum_id = pa2.forum_id
ORDER BY total_posts DESC
LIMIT 10
