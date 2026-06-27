WITH forum_moderator AS (
    SELECT f.id AS forum_id,
           f.title AS forum_title,
           p.first_name AS moderator_first_name,
           p.last_name AS moderator_last_name
    FROM forum f
    JOIN person p ON f.moderator_person_id = p.id
),
forum_member_counts AS (
    SELECT fmmp.forum_id,
           COUNT(DISTINCT fmmp.person_id) AS member_count
    FROM forum_has_member_person fmmp
    GROUP BY fmmp.forum_id
),
post_like_counts AS (
    SELECT p.id AS post_id,
           p.container_forum_id AS forum_id,
           p.length AS post_length,
           COUNT(plp.person_id) AS like_count
    FROM post p
    LEFT JOIN person_likes_post plp ON plp.post_id = p.id
    GROUP BY p.id, p.container_forum_id, p.length
),
forum_post_stats AS (
    SELECT plc.forum_id,
           COUNT(plc.post_id) AS post_count,
           AVG(plc.post_length) AS avg_post_length,
           SUM(plc.like_count) AS total_likes,
           CASE WHEN COUNT(plc.post_id) = 0 THEN 0
                ELSE SUM(plc.like_count) * 1.0 / COUNT(plc.post_id)
           END AS avg_likes_per_post
    FROM post_like_counts plc
    GROUP BY plc.forum_id
)
SELECT fm.forum_id,
       fm.forum_title,
       fm.moderator_first_name,
       fm.moderator_last_name,
       COALESCE(fmc.member_count, 0) AS member_count,
       COALESCE(fps.post_count, 0) AS post_count,
       fps.avg_post_length,
       fps.total_likes,
       fps.avg_likes_per_post
FROM forum_moderator fm
LEFT JOIN forum_member_counts fmc ON fmc.forum_id = fm.forum_id
LEFT JOIN forum_post_stats fps ON fps.forum_id = fm.forum_id
ORDER BY member_count DESC
LIMIT 10
