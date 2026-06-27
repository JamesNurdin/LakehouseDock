WITH comment_stats AS (
    SELECT
        creator_person_id AS creator_id,
        COUNT(*) AS comment_count,
        SUM(length) AS total_comment_length
    FROM comment
    GROUP BY creator_person_id
),
likes_stats AS (
    SELECT
        c.creator_person_id AS creator_id,
        COUNT(lc.person_id) AS total_likes_received,
        SUM(CASE WHEN pkp.person1_id IS NOT NULL THEN 1 ELSE 0 END) AS friend_likes_received
    FROM comment c
    LEFT JOIN person_likes_comment lc
        ON lc.comment_id = c.id
    LEFT JOIN person_knows_person pkp
        ON (pkp.person1_id = c.creator_person_id AND pkp.person2_id = lc.person_id)
        OR (pkp.person2_id = c.creator_person_id AND pkp.person1_id = lc.person_id)
    GROUP BY c.creator_person_id
)
SELECT
    p.id AS person_id,
    p.first_name,
    p.last_name,
    city.name AS city_name,
    COALESCE(cs.comment_count, 0) AS comment_count,
    COALESCE(cs.total_comment_length, 0) AS total_comment_length,
    COALESCE(ls.total_likes_received, 0) AS total_likes_received,
    COALESCE(ls.friend_likes_received, 0) AS friend_likes_received,
    CASE
        WHEN COALESCE(cs.comment_count, 0) = 0 THEN 0
        ELSE CAST(COALESCE(ls.friend_likes_received, 0) AS double) / cs.comment_count
    END AS avg_friend_likes_per_comment
FROM person p
LEFT JOIN place city
    ON p.location_city_id = city.id
LEFT JOIN comment_stats cs
    ON cs.creator_id = p.id
LEFT JOIN likes_stats ls
    ON ls.creator_id = p.id
ORDER BY total_likes_received DESC
LIMIT 10
