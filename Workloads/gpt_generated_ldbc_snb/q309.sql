WITH post_stats AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(*) AS post_count,
        AVG(p.length) AS avg_post_length
    FROM post p
    GROUP BY p.container_forum_id
),
member_stats AS (
    SELECT
        fm.forum_id,
        COUNT(DISTINCT fm.person_id) AS member_count
    FROM forum_has_member_person fm
    GROUP BY fm.forum_id
),
moderator_conn AS (
    SELECT
        f.id AS forum_id,
        COUNT(DISTINCT pk.person2_id) AS moderator_connection_count
    FROM forum f
    JOIN person mod
        ON f.moderator_person_id = mod.id
    LEFT JOIN person_knows_person pk
        ON pk.person1_id = mod.id
    GROUP BY f.id
)
SELECT
    f.id AS forum_id,
    f.title AS forum_title,
    COALESCE(p.avg_post_length, 0) AS avg_post_length,
    COALESCE(m.member_count, 0) AS member_count,
    COALESCE(mc.moderator_connection_count, 0) AS moderator_connection_count
FROM forum f
LEFT JOIN post_stats p
    ON p.forum_id = f.id
LEFT JOIN member_stats m
    ON m.forum_id = f.id
LEFT JOIN moderator_conn mc
    ON mc.forum_id = f.id
WHERE COALESCE(m.member_count, 0) >= 10
  AND COALESCE(mc.moderator_connection_count, 0) >= 5
ORDER BY avg_post_length DESC
LIMIT 5
