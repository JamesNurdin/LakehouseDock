/*
  Analytical query: forum activity overview
  - Shows each forum with its moderator name, member count, post count,
    average post length, and number of distinct post creators.
  - Uses only the selected tables and the allowed join relationships.
*/
WITH member_counts AS (
    SELECT
        fm.forum_id,
        COUNT(DISTINCT fm.person_id) AS member_count
    FROM forum_has_member_person fm
    GROUP BY fm.forum_id
),
post_stats AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(*) AS post_count,
        AVG(p.length) AS avg_post_length,
        COUNT(DISTINCT p.creator_person_id) AS distinct_creator_count
    FROM post p
    GROUP BY p.container_forum_id
)
SELECT
    f.id AS forum_id,
    f.title,
    f.creation_date AS forum_creation_date,
    p_mod.first_name AS moderator_first_name,
    p_mod.last_name AS moderator_last_name,
    COALESCE(mc.member_count, 0) AS member_count,
    COALESCE(ps.post_count, 0) AS post_count,
    ps.avg_post_length,
    COALESCE(ps.distinct_creator_count, 0) AS distinct_creator_count
FROM forum f
LEFT JOIN person p_mod
    ON f.moderator_person_id = p_mod.id
LEFT JOIN member_counts mc
    ON mc.forum_id = f.id
LEFT JOIN post_stats ps
    ON ps.forum_id = f.id
ORDER BY post_count DESC
LIMIT 20
