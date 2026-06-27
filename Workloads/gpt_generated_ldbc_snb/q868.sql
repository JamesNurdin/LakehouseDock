WITH forum_stats AS (
    SELECT
        f.id AS forum_id,
        f.title AS forum_title,
        f.creation_date AS forum_creation_date,
        mod_p.first_name AS moderator_first_name,
        mod_p.last_name AS moderator_last_name,
        COUNT(plp.person_id) AS total_likes,
        COUNT(DISTINCT p.id) AS distinct_posts,
        AVG(p.length) AS avg_post_length
    FROM forum f
    JOIN post p ON p.container_forum_id = f.id
    LEFT JOIN person_likes_post plp ON plp.post_id = p.id
    JOIN person mod_p ON f.moderator_person_id = mod_p.id
    GROUP BY f.id, f.title, f.creation_date, mod_p.first_name, mod_p.last_name
)
SELECT
    forum_id,
    forum_title,
    forum_creation_date,
    moderator_first_name,
    moderator_last_name,
    total_likes,
    distinct_posts,
    avg_post_length
FROM forum_stats
ORDER BY total_likes DESC
LIMIT 10
