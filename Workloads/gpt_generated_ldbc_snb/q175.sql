WITH member_counts AS (
    SELECT forum_id,
           COUNT(DISTINCT person_id) AS member_count
    FROM forum_has_member_person
    GROUP BY forum_id
),
post_stats AS (
    SELECT container_forum_id AS forum_id,
           COUNT(DISTINCT id) AS post_count,
           AVG(length) AS avg_post_length
    FROM post
    GROUP BY container_forum_id
),
comment_stats AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(DISTINCT c.id) AS comment_count,
           AVG(c.length) AS avg_comment_length
    FROM post p
    JOIN comment c ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
),
post_like_stats AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(pl.person_id) AS post_like_count
    FROM post p
    JOIN person_likes_post pl ON pl.post_id = p.id
    GROUP BY p.container_forum_id
),
comment_like_stats AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(cl.person_id) AS comment_like_count
    FROM post p
    JOIN comment c ON c.parent_post_id = p.id
    JOIN person_likes_comment cl ON cl.comment_id = c.id
    GROUP BY p.container_forum_id
)
SELECT f.id AS forum_id,
       f.title,
       mod.first_name AS moderator_first_name,
       mod.last_name AS moderator_last_name,
       COALESCE(m.member_count, 0) AS member_count,
       COALESCE(p.post_count, 0) AS post_count,
       COALESCE(p.avg_post_length, 0) AS avg_post_length,
       COALESCE(c.comment_count, 0) AS comment_count,
       COALESCE(c.avg_comment_length, 0) AS avg_comment_length,
       COALESCE(pl.post_like_count, 0) AS post_like_count,
       COALESCE(cl.comment_like_count, 0) AS comment_like_count
FROM forum f
LEFT JOIN member_counts m ON f.id = m.forum_id
LEFT JOIN post_stats p ON f.id = p.forum_id
LEFT JOIN comment_stats c ON f.id = c.forum_id
LEFT JOIN post_like_stats pl ON f.id = pl.forum_id
LEFT JOIN comment_like_stats cl ON f.id = cl.forum_id
LEFT JOIN person mod ON f.moderator_person_id = mod.id
ORDER BY f.id
