-- Top 10 most active persons based on comments written, likes given to comments, and likes received on their comments
WITH comment_counts AS (
    SELECT
        p.id AS person_id,
        p.first_name,
        p.last_name,
        COUNT(c.id) AS comment_count
    FROM person p
    LEFT JOIN comment c
        ON c.creator_person_id = p.id
    GROUP BY p.id, p.first_name, p.last_name
),
likes_given_counts AS (
    SELECT
        p.id AS person_id,
        COUNT(plc.comment_id) AS likes_given_count
    FROM person p
    LEFT JOIN person_likes_comment plc
        ON plc.person_id = p.id
    GROUP BY p.id
),
likes_received_counts AS (
    SELECT
        c.creator_person_id AS person_id,
        COUNT(plc.comment_id) AS likes_received_count
    FROM comment c
    LEFT JOIN person_likes_comment plc
        ON plc.comment_id = c.id
    GROUP BY c.creator_person_id
)
SELECT
    cc.person_id,
    cc.first_name,
    cc.last_name,
    cc.comment_count,
    COALESCE(lgc.likes_given_count, 0) AS likes_given_count,
    COALESCE(lrc.likes_received_count, 0) AS likes_received_count,
    (cc.comment_count + COALESCE(lgc.likes_given_count, 0) + COALESCE(lrc.likes_received_count, 0)) AS total_activity
FROM comment_counts cc
LEFT JOIN likes_given_counts lgc
    ON lgc.person_id = cc.person_id
LEFT JOIN likes_received_counts lrc
    ON lrc.person_id = cc.person_id
ORDER BY total_activity DESC
LIMIT 10
