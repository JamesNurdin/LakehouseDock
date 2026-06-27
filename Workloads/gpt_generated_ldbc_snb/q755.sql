WITH forum_mod AS (
    SELECT f.id AS forum_id,
           f.title,
           f.creation_date,
           mod.id AS moderator_id,
           mod.first_name AS moderator_first_name,
           mod.last_name AS moderator_last_name
    FROM forum f
    JOIN person mod ON f.moderator_person_id = mod.id
),
post_stats AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(*) AS post_count,
           AVG(p.length) AS avg_post_length
    FROM post p
    GROUP BY p.container_forum_id
),
member_stats AS (
    SELECT fm.forum_id,
           COUNT(DISTINCT fm.person_id) AS member_count
    FROM forum_has_member_person fm
    GROUP BY fm.forum_id
),
member_knows_mod AS (
    SELECT fm.forum_id,
           COUNT(DISTINCT fm.person_id) AS member_knows_mod_count
    FROM forum_has_member_person fm
    JOIN person_knows_person pkp
      ON pkp.person1_id = fm.person_id
    JOIN forum_mod fm_mod
      ON fm_mod.forum_id = fm.forum_id
    WHERE pkp.person2_id = fm_mod.moderator_id
    GROUP BY fm.forum_id
)
SELECT fm.forum_id,
       fm.title,
       fm.moderator_first_name,
       fm.moderator_last_name,
       COALESCE(ps.post_count, 0) AS post_count,
       COALESCE(ps.avg_post_length, 0.0) AS avg_post_length,
       COALESCE(ms.member_count, 0) AS member_count,
       COALESCE(mk.member_knows_mod_count, 0) AS member_knows_moderator_count
FROM forum_mod fm
LEFT JOIN post_stats ps ON ps.forum_id = fm.forum_id
LEFT JOIN member_stats ms ON ms.forum_id = fm.forum_id
LEFT JOIN member_knows_mod mk ON mk.forum_id = fm.forum_id
ORDER BY post_count DESC
LIMIT 10
