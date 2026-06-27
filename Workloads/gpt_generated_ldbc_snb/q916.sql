WITH forum_members AS (
    SELECT
        f.id AS forum_id,
        f.title,
        f.moderator_person_id,
        p_mod.first_name AS moderator_first_name,
        p_mod.last_name AS moderator_last_name,
        p_mod.gender AS moderator_gender,
        COUNT(DISTINCT fm.person_id) AS member_count,
        COUNT(DISTINCT CASE WHEN p_mem.gender = 'male' THEN p_mem.id END) AS male_member_count,
        COUNT(DISTINCT CASE WHEN p_mem.gender = 'female' THEN p_mem.id END) AS female_member_count,
        COUNT(DISTINCT p_mem.browser_used) AS distinct_browser_count
    FROM forum f
    LEFT JOIN forum_has_member_person fm
        ON fm.forum_id = f.id
    LEFT JOIN person p_mem
        ON p_mem.id = fm.person_id
    LEFT JOIN person p_mod
        ON p_mod.id = f.moderator_person_id
    GROUP BY
        f.id,
        f.title,
        f.moderator_person_id,
        p_mod.first_name,
        p_mod.last_name,
        p_mod.gender
)
SELECT
    forum_id,
    title,
    moderator_first_name,
    moderator_last_name,
    moderator_gender,
    member_count,
    male_member_count,
    female_member_count,
    distinct_browser_count
FROM forum_members
ORDER BY member_count DESC
LIMIT 10
