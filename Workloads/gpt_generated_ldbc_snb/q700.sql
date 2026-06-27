WITH forum_base AS (
    SELECT
        f.id AS forum_id,
        f.title AS forum_title,
        f.creation_date AS forum_creation_date,
        m.id AS moderator_id,
        m.first_name AS moderator_first_name,
        m.last_name AS moderator_last_name,
        o.name AS moderator_company_name
    FROM forum f
    LEFT JOIN person m ON f.moderator_person_id = m.id
    LEFT JOIN person_work_at_company pwc ON pwc.person_id = m.id
    LEFT JOIN organisation o ON pwc.company_id = o.id
)
SELECT
    fb.forum_id,
    fb.forum_title,
    fb.forum_creation_date,
    fb.moderator_first_name,
    fb.moderator_last_name,
    fb.moderator_company_name,
    COUNT(DISTINCT p.id) AS post_count,
    COUNT(DISTINCT c.id) AS comment_count,
    COUNT(DISTINCT plp.person_id) AS post_like_user_count,
    COUNT(DISTINCT plc.person_id) AS comment_like_user_count,
    COUNT(DISTINCT fm.person_id) AS member_count,
    AVG(p.length) AS avg_post_length,
    AVG(c.length) AS avg_comment_length
FROM forum_base fb
LEFT JOIN post p ON p.container_forum_id = fb.forum_id
LEFT JOIN comment c ON c.parent_post_id = p.id
LEFT JOIN person_likes_post plp ON plp.post_id = p.id
LEFT JOIN person_likes_comment plc ON plc.comment_id = c.id
LEFT JOIN forum_has_member_person fm ON fm.forum_id = fb.forum_id
GROUP BY
    fb.forum_id,
    fb.forum_title,
    fb.forum_creation_date,
    fb.moderator_first_name,
    fb.moderator_last_name,
    fb.moderator_company_name
ORDER BY post_count DESC
LIMIT 10
