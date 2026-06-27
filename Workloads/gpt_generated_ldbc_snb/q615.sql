WITH member_counts AS (
    SELECT forum_id,
           COUNT(DISTINCT person_id) AS member_count
    FROM forum_has_member_person
    GROUP BY forum_id
),
post_stats AS (
    SELECT container_forum_id,
           COUNT(DISTINCT id) AS post_count,
           AVG(length) AS avg_post_length
    FROM post
    GROUP BY container_forum_id
),
like_counts AS (
    SELECT p.container_forum_id,
           COUNT(pl.person_id) AS total_likes
    FROM person_likes_post pl
    JOIN post p ON pl.post_id = p.id
    GROUP BY p.container_forum_id
)
SELECT f.id AS forum_id,
       f.title,
       f.creation_date,
       p_mod.first_name,
       p_mod.last_name,
       mc.member_count,
       ps.post_count,
       ps.avg_post_length,
       lc.total_likes,
       CASE WHEN ps.post_count > 0 THEN lc.total_likes / ps.post_count ELSE 0 END AS avg_likes_per_post
FROM forum f
JOIN person p_mod ON f.moderator_person_id = p_mod.id
LEFT JOIN member_counts mc ON f.id = mc.forum_id
LEFT JOIN post_stats ps ON f.id = ps.container_forum_id
LEFT JOIN like_counts lc ON f.id = lc.container_forum_id
ORDER BY ps.avg_post_length DESC
LIMIT 10
