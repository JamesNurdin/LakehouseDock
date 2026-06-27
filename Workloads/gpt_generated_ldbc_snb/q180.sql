WITH post_agg AS (
    SELECT
        f.id AS forum_id,
        f.title AS forum_title,
        COUNT(p.id) AS post_count,
        SUM(p.length) AS total_post_length,
        AVG(p.length) AS avg_post_length,
        COUNT(DISTINCT p.location_country_id) AS distinct_post_countries,
        array_agg(DISTINCT pl.name) FILTER (WHERE pl.name IS NOT NULL) AS post_country_names
    FROM forum f
    JOIN post p ON p.container_forum_id = f.id
    LEFT JOIN place pl ON pl.id = p.location_country_id
    GROUP BY f.id, f.title
),
comment_agg AS (
    SELECT
        f.id AS forum_id,
        COUNT(c.id) AS comment_count,
        SUM(c.length) AS total_comment_length,
        AVG(c.length) AS avg_comment_length,
        COUNT(DISTINCT c.location_country_id) AS distinct_comment_countries,
        array_agg(DISTINCT plc.name) FILTER (WHERE plc.name IS NOT NULL) AS comment_country_names
    FROM forum f
    JOIN post p ON p.container_forum_id = f.id
    JOIN comment c ON c.parent_post_id = p.id
    LEFT JOIN place plc ON plc.id = c.location_country_id
    GROUP BY f.id
),
participant_agg AS (
    SELECT
        participants.forum_id,
        COUNT(DISTINCT participants.person_id) AS participant_count
    FROM (
        SELECT f.id AS forum_id, p.creator_person_id AS person_id
        FROM forum f
        JOIN post p ON p.container_forum_id = f.id
        UNION
        SELECT f.id AS forum_id, c.creator_person_id AS person_id
        FROM forum f
        JOIN post p ON p.container_forum_id = f.id
        JOIN comment c ON c.parent_post_id = p.id
    ) participants
    GROUP BY participants.forum_id
)
SELECT
    pa.forum_id,
    pa.forum_title,
    pa.post_count,
    pa.total_post_length,
    pa.avg_post_length,
    pa.distinct_post_countries,
    pa.post_country_names,
    ca.comment_count,
    ca.total_comment_length,
    ca.avg_comment_length,
    ca.distinct_comment_countries,
    ca.comment_country_names,
    pr.participant_count
FROM post_agg pa
LEFT JOIN comment_agg ca ON ca.forum_id = pa.forum_id
LEFT JOIN participant_agg pr ON pr.forum_id = pa.forum_id
ORDER BY pa.forum_id
