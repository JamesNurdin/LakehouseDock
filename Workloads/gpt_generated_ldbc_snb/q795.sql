WITH forum_activity AS (
    SELECT
        f.id AS forum_id,
        f.title AS forum_title,
        CONCAT(mod_p.first_name, ' ', mod_p.last_name) AS moderator_name,
        COUNT(DISTINCT p_creator.id) AS distinct_post_creators,
        COUNT(DISTINCT c_creator.id) AS distinct_comment_creators,
        COUNT(p.id) AS post_count,
        COUNT(c.id) AS comment_count,
        COUNT(CASE WHEN c.parent_comment_id IS NULL THEN 1 END) AS top_level_comment_count,
        COUNT(CASE WHEN c.parent_comment_id IS NOT NULL THEN 1 END) AS reply_comment_count,
        AVG(c.length) AS avg_comment_length,
        SUM(c.length) AS total_comment_length
    FROM forum f
    LEFT JOIN person mod_p
        ON f.moderator_person_id = mod_p.id
    LEFT JOIN post p
        ON p.container_forum_id = f.id
    LEFT JOIN person p_creator
        ON p.creator_person_id = p_creator.id
    LEFT JOIN comment c
        ON c.parent_post_id = p.id
    LEFT JOIN person c_creator
        ON c.creator_person_id = c_creator.id
    GROUP BY f.id, f.title, mod_p.first_name, mod_p.last_name
)
SELECT
    forum_id,
    forum_title,
    moderator_name,
    distinct_post_creators,
    distinct_comment_creators,
    post_count,
    comment_count,
    top_level_comment_count,
    reply_comment_count,
    avg_comment_length,
    total_comment_length
FROM forum_activity
ORDER BY post_count DESC
LIMIT 10
