WITH tag_forums AS (
    SELECT
        t.id AS tag_id,
        t.name AS tag_name,
        f.id AS forum_id,
        f.title AS forum_title,
        f.moderator_person_id
    FROM tag t
    JOIN forum_has_tag_tag ft
        ON ft.tag_id = t.id
    JOIN forum f
        ON ft.forum_id = f.id
)
SELECT
    tag_name,
    COUNT(DISTINCT forum_id) AS forum_count,
    COUNT(DISTINCT moderator_person_id) AS moderator_count,
    CAST(COUNT(DISTINCT forum_id) AS double) / NULLIF(COUNT(DISTINCT moderator_person_id), 0) AS avg_forums_per_moderator,
    AVG(LENGTH(forum_title)) AS avg_title_length
FROM tag_forums
GROUP BY tag_name
ORDER BY avg_forums_per_moderator DESC
LIMIT 5
