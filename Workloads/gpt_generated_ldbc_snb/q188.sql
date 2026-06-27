WITH friend_counts AS (
    SELECT person_id,
           COUNT(DISTINCT friend_id) AS friend_count
    FROM (
        SELECT pk.person1_id AS person_id,
               pk.person2_id AS friend_id
        FROM person_knows_person pk
        UNION ALL
        SELECT pk.person2_id AS person_id,
               pk.person1_id AS friend_id
        FROM person_knows_person pk
    ) f
    GROUP BY person_id
),
interest_counts AS (
    SELECT person_id,
           COUNT(DISTINCT tag_id) AS interest_count
    FROM person_has_interest_tag
    GROUP BY person_id
),
likes_counts AS (
    SELECT person_id,
           COUNT(DISTINCT post_id) AS likes_given
    FROM person_likes_post
    GROUP BY person_id
),
posts_created_counts AS (
    SELECT creator_person_id AS person_id,
           COUNT(*) AS posts_created,
           AVG(length) AS avg_post_length
    FROM post
    GROUP BY creator_person_id
)
SELECT p.id,
       p.first_name,
       p.last_name,
       p.gender,
       p.birthday,
       COALESCE(fc.friend_count, 0)      AS friend_count,
       COALESCE(ic.interest_count, 0)    AS interest_count,
       COALESCE(lc.likes_given, 0)       AS likes_given,
       COALESCE(pc.posts_created, 0)     AS posts_created,
       pc.avg_post_length
FROM person p
LEFT JOIN friend_counts fc ON fc.person_id = p.id
LEFT JOIN interest_counts ic ON ic.person_id = p.id
LEFT JOIN likes_counts lc ON lc.person_id = p.id
LEFT JOIN posts_created_counts pc ON pc.person_id = p.id
ORDER BY likes_given DESC
LIMIT 10
