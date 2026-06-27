-- Top 20 most liked commenters with a summary of their activity
WITH comments_agg AS (
    SELECT
        c.creator_person_id AS person_id,
        COUNT(*) AS total_comments,
        AVG(c.length) AS avg_comment_length,
        SUM(c.length) AS sum_comment_length
    FROM comment c
    GROUP BY c.creator_person_id
),
likes_agg AS (
    SELECT
        c.creator_person_id AS person_id,
        COUNT(plc.person_id) AS total_likes
    FROM comment c
    LEFT JOIN person_likes_comment plc
        ON c.id = plc.comment_id
    GROUP BY c.creator_person_id
),
tags_agg AS (
    SELECT
        pht.person_id,
        COUNT(DISTINCT pht.tag_id) AS distinct_tags
    FROM person_has_interest_tag pht
    GROUP BY pht.person_id
),
friends_agg AS (
    SELECT
        f.person_id,
        COUNT(DISTINCT f.friend_id) AS friend_count
    FROM (
        SELECT person1_id AS person_id, person2_id AS friend_id FROM person_knows_person
        UNION ALL
        SELECT person2_id AS person_id, person1_id AS friend_id FROM person_knows_person
    ) f
    GROUP BY f.person_id
)
SELECT
    p.id,
    p.first_name,
    p.last_name,
    p.gender,
    city.name AS city_name,
    ca.total_comments,
    ca.avg_comment_length,
    la.total_likes,
    ta.distinct_tags,
    fa.friend_count
FROM person p
LEFT JOIN place city
    ON p.location_city_id = city.id
LEFT JOIN comments_agg ca
    ON p.id = ca.person_id
LEFT JOIN likes_agg la
    ON p.id = la.person_id
LEFT JOIN tags_agg ta
    ON p.id = ta.person_id
LEFT JOIN friends_agg fa
    ON p.id = fa.person_id
WHERE city.type = 'City'
ORDER BY la.total_likes DESC NULLS LAST,
         ca.total_comments DESC NULLS LAST
LIMIT 20
