WITH forum_stats AS (
    SELECT
        f.id AS forum_id,
        f.title AS forum_title,
        mod.first_name AS moderator_first_name,
        mod.last_name AS moderator_last_name,
        COUNT(DISTINCT p.id) AS post_count,
        AVG(p.length) AS avg_post_length,
        COUNT(DISTINCT fm.person_id) AS member_count,
        COUNT(DISTINCT ft.tag_id) AS tag_count,
        SUM(CASE WHEN mem.gender = 'male' THEN 1 ELSE 0 END) AS male_member_count,
        SUM(CASE WHEN mem.gender = 'female' THEN 1 ELSE 0 END) AS female_member_count,
        ARRAY_AGG(DISTINCT t.name) AS tag_names
    FROM forum f
    LEFT JOIN person mod
        ON f.moderator_person_id = mod.id
    LEFT JOIN post p
        ON p.container_forum_id = f.id
    LEFT JOIN forum_has_member_person fm
        ON fm.forum_id = f.id
    LEFT JOIN person mem
        ON fm.person_id = mem.id
    LEFT JOIN forum_has_tag_tag ft
        ON ft.forum_id = f.id
    LEFT JOIN tag t
        ON ft.tag_id = t.id
    GROUP BY f.id, f.title, mod.first_name, mod.last_name
)

SELECT
    forum_id,
    forum_title,
    moderator_first_name,
    moderator_last_name,
    post_count,
    avg_post_length,
    member_count,
    tag_count,
    male_member_count,
    female_member_count,
    tag_names
FROM forum_stats
ORDER BY post_count DESC, avg_post_length DESC
LIMIT 20
