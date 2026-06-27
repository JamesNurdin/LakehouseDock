WITH friends AS (
    SELECT person1_id AS person_id, person2_id AS friend_id
    FROM person_knows_person
    UNION ALL
    SELECT person2_id AS person_id, person1_id AS friend_id
    FROM person_knows_person
),
friend_counts AS (
    SELECT person_id, COUNT(DISTINCT friend_id) AS friend_count
    FROM friends
    GROUP BY person_id
),
post_stats AS (
    SELECT p.creator_person_id AS person_id,
           COUNT(*) AS post_count,
           SUM(p.length) AS total_post_length,
           AVG(p.length) AS avg_post_length
    FROM post p
    GROUP BY p.creator_person_id
),
likes_received AS (
    SELECT p.creator_person_id AS creator_id,
           COUNT(*) AS likes_received
    FROM person_likes_post plp
    JOIN post p ON plp.post_id = p.id
    GROUP BY p.creator_person_id
),
likes_given AS (
    SELECT person_id, COUNT(*) AS likes_given
    FROM person_likes_post
    GROUP BY person_id
)
SELECT
    p.id,
    p.first_name,
    p.last_name,
    p.gender,
    c.name AS city_name,
    COALESCE(fc.friend_count, 0) AS friend_count,
    COALESCE(ps.post_count, 0) AS post_count,
    COALESCE(ps.total_post_length, 0) AS total_post_length,
    COALESCE(ps.avg_post_length, 0) AS avg_post_length,
    COALESCE(lg.likes_given, 0) AS likes_given,
    COALESCE(lr.likes_received, 0) AS likes_received
FROM person p
LEFT JOIN place c ON p.location_city_id = c.id
LEFT JOIN friend_counts fc ON p.id = fc.person_id
LEFT JOIN post_stats ps ON p.id = ps.person_id
LEFT JOIN likes_given lg ON p.id = lg.person_id
LEFT JOIN likes_received lr ON p.id = lr.creator_id
ORDER BY p.id
LIMIT 100
