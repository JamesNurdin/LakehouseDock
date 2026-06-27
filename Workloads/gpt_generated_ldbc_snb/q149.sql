WITH tag_likes_per_forum AS (
    SELECT
        f.id AS forum_id,
        f.title AS forum_title,
        moderator.first_name AS moderator_first_name,
        moderator.last_name AS moderator_last_name,
        t.id AS tag_id,
        t.name AS tag_name,
        COUNT(DISTINCT p.id) AS post_count,
        COUNT(pl.person_id) AS like_count,
        SUM(p.length) / COUNT(DISTINCT p.id) AS avg_post_length
    FROM forum f
    JOIN person moderator ON f.moderator_person_id = moderator.id
    JOIN post p ON p.container_forum_id = f.id
    JOIN post_has_tag_tag pt ON pt.post_id = p.id
    JOIN tag t ON t.id = pt.tag_id
    LEFT JOIN person_likes_post pl ON pl.post_id = p.id
    GROUP BY f.id, f.title, moderator.first_name, moderator.last_name, t.id, t.name
),
ranked_tags AS (
    SELECT
        forum_id,
        forum_title,
        moderator_first_name,
        moderator_last_name,
        tag_id,
        tag_name,
        post_count,
        like_count,
        avg_post_length,
        ROW_NUMBER() OVER (PARTITION BY forum_id ORDER BY like_count DESC) AS tag_rank
    FROM tag_likes_per_forum
)
SELECT
    forum_id,
    forum_title,
    moderator_first_name,
    moderator_last_name,
    tag_id,
    tag_name,
    post_count,
    like_count,
    avg_post_length,
    tag_rank
FROM ranked_tags
WHERE tag_rank <= 3
ORDER BY forum_id, tag_rank
