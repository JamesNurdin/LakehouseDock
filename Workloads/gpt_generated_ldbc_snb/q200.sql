WITH forum_metrics AS (
    SELECT
        f.id AS forum_id,
        f.title,
        f.creation_date AS forum_creation_date,
        pm.first_name AS moderator_first_name,
        pm.last_name AS moderator_last_name,
        pm.gender AS moderator_gender,
        COUNT(DISTINCT fm.person_id) AS member_count,
        COUNT(DISTINCT ft.tag_id) AS tag_count,
        COUNT(p.id) AS post_count,
        AVG(p.length) AS avg_post_length,
        COUNT(DISTINCT p.creator_person_id) AS distinct_creator_count,
        SUM(CASE WHEN p.creator_person_id = f.moderator_person_id THEN 1 ELSE 0 END) AS moderator_post_count
    FROM forum f
    LEFT JOIN forum_has_member_person fm ON fm.forum_id = f.id
    LEFT JOIN forum_has_tag_tag ft ON ft.forum_id = f.id
    LEFT JOIN post p ON p.container_forum_id = f.id
    LEFT JOIN person pm ON f.moderator_person_id = pm.id
    GROUP BY
        f.id,
        f.title,
        f.creation_date,
        pm.first_name,
        pm.last_name,
        pm.gender
)
SELECT
    forum_id,
    title,
    forum_creation_date,
    moderator_first_name,
    moderator_last_name,
    moderator_gender,
    member_count,
    tag_count,
    post_count,
    avg_post_length,
    distinct_creator_count,
    moderator_post_count,
    CASE WHEN post_count > 0 THEN moderator_post_count * 1.0 / post_count ELSE 0 END AS moderator_post_ratio
FROM forum_metrics
ORDER BY post_count DESC
LIMIT 10
