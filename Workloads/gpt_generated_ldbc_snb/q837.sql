WITH forum_stats AS (
    SELECT
        f.id AS forum_id,
        f.title AS forum_title,
        mod.id AS moderator_id,
        mod.first_name AS moderator_first_name,
        mod.last_name AS moderator_last_name,
        COUNT(DISTINCT p.id) AS post_count,
        COUNT(pl.person_id) AS total_likes
    FROM forum f
    JOIN person mod
        ON f.moderator_person_id = mod.id
    -- Only keep forums that are tagged with the "technology" tag
    JOIN forum_has_tag_tag ft
        ON ft.forum_id = f.id
    JOIN tag t
        ON ft.tag_id = t.id
    LEFT JOIN post p
        ON p.container_forum_id = f.id
    LEFT JOIN person_likes_post pl
        ON pl.post_id = p.id
    WHERE t.name = 'technology'
    GROUP BY f.id, f.title, mod.id, mod.first_name, mod.last_name
)
SELECT
    forum_id,
    forum_title,
    moderator_first_name,
    moderator_last_name,
    post_count,
    total_likes,
    CASE WHEN post_count = 0 THEN 0 ELSE total_likes * 1.0 / post_count END AS avg_likes_per_post
FROM forum_stats
ORDER BY avg_likes_per_post DESC
LIMIT 5
