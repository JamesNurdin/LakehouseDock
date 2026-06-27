WITH forum_summary AS (
    SELECT
        f.id AS forum_id,
        f.title AS forum_title,
        p_mod.first_name AS moderator_first_name,
        p_mod.last_name AS moderator_last_name,
        COUNT(DISTINCT fm.person_id) AS member_count,
        COUNT(p.id) AS post_count,
        AVG(p.length) AS avg_post_length,
        COUNT(DISTINCT p.creator_person_id) AS distinct_creator_count,
        COUNT(DISTINCT ft.tag_id) AS tag_count,
        array_join(array_agg(DISTINCT t.name), ', ') AS tag_names
    FROM forum AS f
    LEFT JOIN forum_has_member_person AS fm
        ON fm.forum_id = f.id
    LEFT JOIN person AS p_mod
        ON f.moderator_person_id = p_mod.id
    LEFT JOIN forum_has_tag_tag AS ft
        ON ft.forum_id = f.id
    LEFT JOIN tag AS t
        ON ft.tag_id = t.id
    LEFT JOIN post AS p
        ON p.container_forum_id = f.id
    GROUP BY
        f.id,
        f.title,
        p_mod.first_name,
        p_mod.last_name
)
SELECT
    forum_id,
    forum_title,
    moderator_first_name,
    moderator_last_name,
    member_count,
    post_count,
    avg_post_length,
    distinct_creator_count,
    tag_count,
    tag_names
FROM forum_summary
ORDER BY post_count DESC
LIMIT 10
