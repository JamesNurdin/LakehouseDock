WITH forum_mod AS (
    SELECT
        f.id AS forum_id,
        f.title,
        p_mod.id AS moderator_id,
        p_mod.first_name AS moderator_first_name,
        p_mod.last_name AS moderator_last_name
    FROM forum f
    JOIN person p_mod
        ON f.moderator_person_id = p_mod.id
),
forum_members AS (
    SELECT
        fm.forum_id,
        fm.person_id AS member_id,
        p_mem.first_name,
        p_mem.last_name
    FROM forum_has_member_person fm
    JOIN person p_mem
        ON fm.person_id = p_mem.id
)
SELECT
    fm.title,
    fm.moderator_first_name,
    fm.moderator_last_name,
    COUNT(DISTINCT mem.member_id) AS total_members,
    SUM(CASE WHEN pk1.person1_id IS NOT NULL OR pk2.person2_id IS NOT NULL THEN 1 ELSE 0 END) AS friend_members,
    CAST(SUM(CASE WHEN pk1.person1_id IS NOT NULL OR pk2.person2_id IS NOT NULL THEN 1 ELSE 0 END) AS double) / NULLIF(COUNT(DISTINCT mem.member_id), 0) AS friend_ratio
FROM forum_mod fm
JOIN forum_members mem
    ON mem.forum_id = fm.forum_id
LEFT JOIN person_knows_person pk1
    ON pk1.person1_id = fm.moderator_id
   AND pk1.person2_id = mem.member_id
LEFT JOIN person_knows_person pk2
    ON pk2.person2_id = fm.moderator_id
   AND pk2.person1_id = mem.member_id
GROUP BY
    fm.title,
    fm.moderator_first_name,
    fm.moderator_last_name
ORDER BY friend_ratio DESC
LIMIT 10
