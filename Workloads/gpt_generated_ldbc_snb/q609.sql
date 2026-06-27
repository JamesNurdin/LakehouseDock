WITH forum_stats AS (
    SELECT
        f.id AS forum_id,
        f.title AS forum_title,
        m_mod.first_name AS moderator_first_name,
        m_mod.last_name AS moderator_last_name,
        COUNT(DISTINCT p.id) AS post_count,
        COUNT(DISTINCT c.id) AS comment_count,
        AVG(p.length) AS avg_post_length,
        AVG(c.length) AS avg_comment_length,
        COUNT(DISTINCT fm.person_id) AS member_count,
        COUNT(plc.person_id) AS total_comment_likes
    FROM forum f
    LEFT JOIN forum_has_member_person fm
        ON fm.forum_id = f.id
    LEFT JOIN person m_mod
        ON f.moderator_person_id = m_mod.id
    LEFT JOIN post p
        ON p.container_forum_id = f.id
    LEFT JOIN comment c
        ON c.parent_post_id = p.id
    LEFT JOIN person_likes_comment plc
        ON plc.comment_id = c.id
    GROUP BY
        f.id,
        f.title,
        m_mod.first_name,
        m_mod.last_name
)
SELECT
    forum_id,
    forum_title,
    moderator_first_name || ' ' || moderator_last_name AS moderator_name,
    post_count,
    comment_count,
    avg_post_length,
    avg_comment_length,
    member_count,
    total_comment_likes,
    CASE
        WHEN comment_count > 0 THEN total_comment_likes * 1.0 / comment_count
        ELSE NULL
    END AS avg_likes_per_comment
FROM forum_stats
ORDER BY post_count DESC
LIMIT 10
