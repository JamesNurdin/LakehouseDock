WITH forum_stats AS (
    SELECT
        f.id AS forum_id,
        f.title AS forum_title,
        f.creation_date AS forum_creation_date,
        COUNT(DISTINCT p.id) AS post_count,
        COUNT(DISTINCT c.id) AS comment_count,
        AVG(p.length) AS avg_post_length,
        AVG(c.length) AS avg_comment_length,
        COUNT(DISTINCT plp.person_id) AS post_like_count,
        COUNT(DISTINCT plp.person_id) * 1.0 / NULLIF(COUNT(DISTINCT p.id), 0) AS avg_likes_per_post,
        COUNT(DISTINCT fhm.person_id) AS member_count,
        mod.first_name || ' ' || mod.last_name AS moderator_name
    FROM forum f
    LEFT JOIN post p ON p.container_forum_id = f.id
    LEFT JOIN comment c ON c.parent_post_id = p.id
    LEFT JOIN person_likes_post plp ON plp.post_id = p.id
    LEFT JOIN forum_has_member_person fhm ON fhm.forum_id = f.id
    LEFT JOIN person mod ON mod.id = f.moderator_person_id
    GROUP BY f.id, f.title, f.creation_date, mod.first_name, mod.last_name
    HAVING COUNT(DISTINCT p.id) > 0
)
SELECT
    forum_id,
    forum_title,
    forum_creation_date,
    post_count,
    comment_count,
    avg_post_length,
    avg_comment_length,
    post_like_count,
    avg_likes_per_post,
    member_count,
    moderator_name
FROM forum_stats
ORDER BY post_count DESC, avg_likes_per_post DESC
LIMIT 10
