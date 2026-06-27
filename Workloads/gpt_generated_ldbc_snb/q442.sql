WITH comment_stats AS (
    SELECT
        c.creator_person_id AS person_id,
        COUNT(*) AS comment_count,
        AVG(c.length) AS avg_comment_length,
        COUNT(DISTINCT c.location_country_id) AS distinct_comment_countries
    FROM comment c
    GROUP BY c.creator_person_id
),
likes_given AS (
    SELECT
        plc.person_id AS person_id,
        COUNT(*) AS likes_given_count
    FROM person_likes_comment plc
    GROUP BY plc.person_id
),
likes_received AS (
    SELECT
        c.creator_person_id AS person_id,
        COUNT(*) AS likes_received_count
    FROM comment c
    JOIN person_likes_comment plc ON plc.comment_id = c.id
    GROUP BY c.creator_person_id
),
friend_counts AS (
    SELECT
        p.id AS person_id,
        COUNT(DISTINCT CASE
            WHEN pk.person1_id = p.id THEN pk.person2_id
            ELSE pk.person1_id
        END) AS friend_count
    FROM person p
    LEFT JOIN person_knows_person pk
        ON pk.person1_id = p.id OR pk.person2_id = p.id
    GROUP BY p.id
),
post_stats AS (
    SELECT
        po.creator_person_id AS person_id,
        COUNT(*) AS post_count,
        AVG(po.length) AS avg_post_length
    FROM post po
    GROUP BY po.creator_person_id
),
study_counts AS (
    SELECT
        psu.person_id AS person_id,
        COUNT(DISTINCT psu.university_id) AS university_count
    FROM person_study_at_university psu
    GROUP BY psu.person_id
)
SELECT
    p.id,
    p.first_name,
    p.last_name,
    p.gender,
    COALESCE(cs.comment_count, 0) AS comment_count,
    COALESCE(cs.avg_comment_length, 0) AS avg_comment_length,
    COALESCE(lg.likes_given_count, 0) AS likes_given,
    COALESCE(lr.likes_received_count, 0) AS likes_received,
    COALESCE(fc.friend_count, 0) AS friend_count,
    COALESCE(ps.post_count, 0) AS post_count,
    COALESCE(ps.avg_post_length, 0) AS avg_post_length,
    COALESCE(sc.university_count, 0) AS university_count,
    COALESCE(cs.distinct_comment_countries, 0) AS distinct_comment_countries
FROM person p
LEFT JOIN comment_stats cs ON cs.person_id = p.id
LEFT JOIN likes_given lg ON lg.person_id = p.id
LEFT JOIN likes_received lr ON lr.person_id = p.id
LEFT JOIN friend_counts fc ON fc.person_id = p.id
LEFT JOIN post_stats ps ON ps.person_id = p.id
LEFT JOIN study_counts sc ON sc.person_id = p.id
ORDER BY comment_count DESC
LIMIT 100
