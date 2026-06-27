WITH moderated_forums AS (
    SELECT
        f.id AS forum_id,
        f.title,
        f.creation_date AS forum_creation_date,
        p.id AS moderator_id,
        p.first_name,
        p.last_name,
        p.gender,
        p.location_city_id,
        p.language
    FROM forum f
    JOIN person p
        ON f.moderator_person_id = p.id
)
SELECT
    moderator_id,
    first_name,
    last_name,
    gender,
    COUNT(forum_id) AS forum_count,
    AVG(length(title)) AS avg_title_length,
    MIN(forum_creation_date) AS earliest_forum_creation,
    MAX(forum_creation_date) AS latest_forum_creation
FROM moderated_forums
GROUP BY
    moderator_id,
    first_name,
    last_name,
    gender
ORDER BY forum_count DESC
LIMIT 10
