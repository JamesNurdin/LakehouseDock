WITH
comment_stats AS (
    SELECT
        creator_person_id,
        COUNT(*) AS comment_count,
        SUM(length) AS total_comment_length,
        AVG(length) AS avg_comment_length
    FROM comment
    GROUP BY creator_person_id
),
likes_given AS (
    SELECT
        person_id,
        COUNT(*) AS likes_given_count
    FROM person_likes_comment
    GROUP BY person_id
),
forum_membership AS (
    SELECT
        person_id,
        COUNT(DISTINCT forum_id) AS forum_count
    FROM forum_has_member_person
    GROUP BY person_id
),
known_counts AS (
    SELECT
        person_id,
        COUNT(DISTINCT known_id) AS known_count
    FROM (
        SELECT person1_id AS person_id, person2_id AS known_id FROM person_knows_person
        UNION ALL
        SELECT person2_id AS person_id, person1_id AS known_id FROM person_knows_person
    ) AS u
    GROUP BY person_id
),
comment_likes_received AS (
    SELECT
        c.creator_person_id,
        COUNT(plc.person_id) AS likes_received
    FROM comment c
    LEFT JOIN person_likes_comment plc
        ON plc.comment_id = c.id
    GROUP BY c.creator_person_id
)
SELECT
    p.id,
    p.first_name,
    p.last_name,
    p.gender,
    cs.comment_count,
    cs.total_comment_length,
    cs.avg_comment_length,
    cl.likes_received,
    lg.likes_given_count,
    fm.forum_count,
    kn.known_count
FROM person p
LEFT JOIN comment_stats cs
    ON cs.creator_person_id = p.id
LEFT JOIN comment_likes_received cl
    ON cl.creator_person_id = p.id
LEFT JOIN likes_given lg
    ON lg.person_id = p.id
LEFT JOIN forum_membership fm
    ON fm.person_id = p.id
LEFT JOIN known_counts kn
    ON kn.person_id = p.id
ORDER BY cs.comment_count DESC NULLS LAST
LIMIT 100
