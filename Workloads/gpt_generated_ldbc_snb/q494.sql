WITH member_counts AS (
    SELECT forum_id,
           COUNT(DISTINCT person_id) AS member_count
    FROM forum_has_member_person
    GROUP BY forum_id
),
post_stats AS (
    SELECT container_forum_id,
           COUNT(*) AS post_count,
           AVG(length) AS avg_post_length,
           MAX(length) AS max_post_length,
           COUNT(DISTINCT creator_person_id) AS distinct_creator_count
    FROM post
    GROUP BY container_forum_id
)
SELECT
    f.id AS forum_id,
    f.title,
    CONCAT(p_mod.first_name, ' ', p_mod.last_name) AS moderator_name,
    COALESCE(m.member_count, 0) AS member_count,
    COALESCE(ps.post_count, 0) AS post_count,
    COALESCE(ps.avg_post_length, 0) AS avg_post_length,
    COALESCE(ps.max_post_length, 0) AS max_post_length,
    COALESCE(ps.distinct_creator_count, 0) AS distinct_creator_count,
    CASE WHEN COALESCE(m.member_count, 0) = 0 THEN 0
         ELSE COALESCE(ps.post_count, 0) * 1.0 / m.member_count END AS posts_per_member
FROM forum f
LEFT JOIN person p_mod
       ON f.moderator_person_id = p_mod.id
LEFT JOIN member_counts m
       ON f.id = m.forum_id
LEFT JOIN post_stats ps
       ON f.id = ps.container_forum_id
ORDER BY f.id
