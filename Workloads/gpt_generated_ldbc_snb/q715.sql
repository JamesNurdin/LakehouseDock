WITH post_likes AS (
    SELECT
        plp.post_id,
        COUNT(*) AS like_count
    FROM person_likes_post plp
    GROUP BY plp.post_id
),
post_tags AS (
    SELECT DISTINCT post_id
    FROM post_has_tag_tag
),
forum_stats AS (
    SELECT
        f.id AS forum_id,
        f.title AS forum_title,
        mod.first_name AS moderator_first_name,
        mod.last_name AS moderator_last_name,
        c.name AS country_name,
        COUNT(DISTINCT p.id) AS post_count,
        SUM(COALESCE(pl.like_count, 0)) AS total_likes,
        AVG(COALESCE(pl.like_count, 0)) AS avg_likes_per_post,
        COUNT(DISTINCT pht.tag_id) AS distinct_tag_count
    FROM forum f
    JOIN person mod ON f.moderator_person_id = mod.id
    JOIN post p ON p.container_forum_id = f.id
    JOIN post_tags pt ON pt.post_id = p.id
    LEFT JOIN post_likes pl ON pl.post_id = p.id
    JOIN place c ON p.location_country_id = c.id
    JOIN post_has_tag_tag pht ON pht.post_id = p.id
    GROUP BY
        f.id,
        f.title,
        mod.first_name,
        mod.last_name,
        c.name
)
SELECT
    forum_id,
    forum_title,
    moderator_first_name,
    moderator_last_name,
    country_name,
    post_count,
    total_likes,
    avg_likes_per_post,
    distinct_tag_count
FROM forum_stats
ORDER BY avg_likes_per_post DESC
LIMIT 10
