WITH forum_stats AS (
    SELECT
        f.id AS forum_id,
        f.title AS forum_title,
        p_mod.first_name AS moderator_first_name,
        p_mod.last_name AS moderator_last_name,
        COUNT(DISTINCT po.id) AS total_posts,
        AVG(po.length) AS avg_post_length,
        COUNT(DISTINCT c.id) AS total_comments,
        AVG(c.length) AS avg_comment_length,
        COUNT(DISTINCT fm.person_id) AS member_count,
        COUNT(DISTINCT po.creator_person_id) AS distinct_post_authors
    FROM forum f
    LEFT JOIN person p_mod
        ON f.moderator_person_id = p_mod.id
    LEFT JOIN forum_has_member_person fm
        ON fm.forum_id = f.id
    LEFT JOIN post po
        ON po.container_forum_id = f.id
    LEFT JOIN comment c
        ON c.parent_post_id = po.id
    GROUP BY f.id, f.title, p_mod.first_name, p_mod.last_name
)
SELECT
    forum_id,
    forum_title,
    moderator_first_name,
    moderator_last_name,
    total_posts,
    avg_post_length,
    total_comments,
    avg_comment_length,
    member_count,
    distinct_post_authors
FROM forum_stats
ORDER BY total_posts DESC
LIMIT 10
