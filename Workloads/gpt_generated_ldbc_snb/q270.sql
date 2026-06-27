SELECT
    f.id AS forum_id,
    f.title AS forum_title,
    mod.first_name AS moderator_first_name,
    mod.last_name AS moderator_last_name,
    (
        SELECT COUNT(DISTINCT p.id)
        FROM post p
        WHERE p.container_forum_id = f.id
    ) AS post_count,
    (
        SELECT AVG(p.length)
        FROM post p
        WHERE p.container_forum_id = f.id
    ) AS avg_post_length,
    (
        SELECT COUNT(DISTINCT c.id)
        FROM comment c
        JOIN post p2 ON c.parent_post_id = p2.id
        WHERE p2.container_forum_id = f.id
    ) AS comment_count,
    (
        SELECT COUNT(DISTINCT fm.person_id)
        FROM forum_has_member_person fm
        WHERE fm.forum_id = f.id
    ) AS member_count,
    (
        SELECT COUNT(DISTINCT ft.tag_id)
        FROM forum_has_tag_tag ft
        WHERE ft.forum_id = f.id
    ) AS tag_count
FROM forum f
LEFT JOIN person mod
    ON mod.id = f.moderator_person_id
ORDER BY post_count DESC
LIMIT 10
