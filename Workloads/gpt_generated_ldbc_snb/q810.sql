WITH friend_counts AS (
    SELECT person_id, count(DISTINCT friend_id) AS friend_count
    FROM (
        SELECT person1_id AS person_id, person2_id AS friend_id FROM person_knows_person
        UNION ALL
        SELECT person2_id AS person_id, person1_id AS friend_id FROM person_knows_person
    ) f
    GROUP BY person_id
),
post_stats AS (
    SELECT creator_person_id AS person_id,
           count(*) AS post_count,
           avg(length) AS avg_post_length
    FROM post
    GROUP BY creator_person_id
),
likes_received AS (
    SELECT po.creator_person_id AS person_id,
           count(*) AS likes_received
    FROM post po
    JOIN person_likes_post plp ON plp.post_id = po.id
    GROUP BY po.creator_person_id
),
likes_given AS (
    SELECT person_id,
           count(*) AS likes_given
    FROM person_likes_post
    GROUP BY person_id
),
interest_tags AS (
    SELECT person_id,
           count(DISTINCT tag_id) AS interest_tag_count
    FROM person_has_interest_tag
    GROUP BY person_id
)
SELECT
    p.id AS person_id,
    p.first_name,
    p.last_name,
    coalesce(fc.friend_count, 0) AS friend_count,
    coalesce(ps.post_count, 0) AS post_count,
    coalesce(ps.avg_post_length, 0) AS avg_post_length,
    coalesce(lr.likes_received, 0) AS likes_received,
    coalesce(lg.likes_given, 0) AS likes_given,
    coalesce(it.interest_tag_count, 0) AS interest_tag_count,
    pl.name AS city_name,
    (coalesce(fc.friend_count, 0) * 2
     + coalesce(lr.likes_received, 0)
     + coalesce(lg.likes_given, 0)
     + coalesce(it.interest_tag_count, 0) * 0.5
     + coalesce(ps.post_count, 0) * 2) AS influence_score
FROM person p
LEFT JOIN friend_counts fc ON fc.person_id = p.id
LEFT JOIN post_stats ps ON ps.person_id = p.id
LEFT JOIN likes_received lr ON lr.person_id = p.id
LEFT JOIN likes_given lg ON lg.person_id = p.id
LEFT JOIN interest_tags it ON it.person_id = p.id
LEFT JOIN place pl ON pl.id = p.location_city_id
ORDER BY influence_score DESC
LIMIT 10
