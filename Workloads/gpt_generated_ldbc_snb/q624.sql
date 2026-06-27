WITH post_metrics AS (
    SELECT
        f.id AS forum_id,
        f.title AS forum_title,
        mod.gender AS moderator_gender,
        city.name AS moderator_city,
        COUNT(p.id) AS post_count,
        CAST(SUM(p.length) AS double) / NULLIF(COUNT(p.id), 0) AS avg_post_length,
        COUNT(DISTINCT creator.id) AS distinct_creators
    FROM forum f
    JOIN person mod ON f.moderator_person_id = mod.id
    LEFT JOIN place city ON mod.location_city_id = city.id
    JOIN post p ON p.container_forum_id = f.id
    JOIN person creator ON p.creator_person_id = creator.id
    GROUP BY f.id, f.title, mod.gender, city.name
),
likes_metrics AS (
    SELECT
        f.id AS forum_id,
        COUNT(plp.person_id) AS total_likes
    FROM forum f
    JOIN post p ON p.container_forum_id = f.id
    LEFT JOIN person_likes_post plp ON plp.post_id = p.id
    GROUP BY f.id
)
SELECT
    pm.forum_id,
    pm.forum_title,
    pm.moderator_gender,
    pm.moderator_city,
    pm.post_count,
    pm.avg_post_length,
    lm.total_likes,
    pm.distinct_creators,
    CAST(lm.total_likes AS double) / NULLIF(pm.post_count, 0) AS avg_likes_per_post
FROM post_metrics pm
LEFT JOIN likes_metrics lm ON pm.forum_id = lm.forum_id
ORDER BY lm.total_likes DESC
LIMIT 10
