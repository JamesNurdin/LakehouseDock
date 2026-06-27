WITH forum_stats AS (
    SELECT
        f.id AS forum_id,
        f.title,
        moderator.first_name AS moderator_first_name,
        moderator.last_name AS moderator_last_name,
        COUNT(DISTINCT p.id) AS post_count,
        AVG(p.length) AS avg_post_length,
        COUNT(plp.person_id) AS total_likes,
        COUNT(DISTINCT fm.person_id) AS member_count,
        COUNT(DISTINCT ft.tag_id) AS tag_count
    FROM forum f
    LEFT JOIN person moderator
        ON f.moderator_person_id = moderator.id
    LEFT JOIN post p
        ON p.container_forum_id = f.id
    LEFT JOIN person_likes_post plp
        ON plp.post_id = p.id
    LEFT JOIN forum_has_member_person fm
        ON fm.forum_id = f.id
    LEFT JOIN forum_has_tag_tag ft
        ON ft.forum_id = f.id
    GROUP BY f.id, f.title, moderator.first_name, moderator.last_name
)
SELECT
    forum_id,
    title,
    moderator_first_name,
    moderator_last_name,
    post_count,
    avg_post_length,
    total_likes,
    member_count,
    tag_count
FROM forum_stats
ORDER BY total_likes DESC
LIMIT 10
