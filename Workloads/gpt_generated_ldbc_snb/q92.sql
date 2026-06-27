/*
  Person activity and network summary:
  - number of friends (both directions)
  - number of posts and comments created
  - likes given to posts and comments
  - likes received on posts and comments
  - city name
  Ordered by friend count descending.
*/
WITH friends AS (
    SELECT
        p.id AS person_id,
        COUNT(DISTINCT f.friend_id) AS friend_count
    FROM person p
    LEFT JOIN (
        SELECT person1_id AS person_id, person2_id AS friend_id
        FROM person_knows_person
        UNION ALL
        SELECT person2_id AS person_id, person1_id AS friend_id
        FROM person_knows_person
    ) f ON f.person_id = p.id
    GROUP BY p.id
),
posts AS (
    SELECT
        creator_person_id AS person_id,
        COUNT(*) AS post_count
    FROM post
    GROUP BY creator_person_id
),
comments AS (
    SELECT
        creator_person_id AS person_id,
        COUNT(*) AS comment_count
    FROM comment
    GROUP BY creator_person_id
),
likes_given_posts AS (
    SELECT
        person_id,
        COUNT(*) AS likes_given_to_posts
    FROM person_likes_post
    GROUP BY person_id
),
likes_given_comments AS (
    SELECT
        person_id,
        COUNT(*) AS likes_given_to_comments
    FROM person_likes_comment
    GROUP BY person_id
),
likes_received_posts AS (
    SELECT
        po.creator_person_id AS person_id,
        COUNT(*) AS likes_received_on_posts
    FROM post po
    JOIN person_likes_post plp ON plp.post_id = po.id
    GROUP BY po.creator_person_id
),
likes_received_comments AS (
    SELECT
        co.creator_person_id AS person_id,
        COUNT(*) AS likes_received_on_comments
    FROM comment co
    JOIN person_likes_comment plc ON plc.comment_id = co.id
    GROUP BY co.creator_person_id
),
person_info AS (
    SELECT
        id AS person_id,
        first_name,
        last_name,
        gender,
        location_city_id
    FROM person
)
SELECT
    pi.person_id,
    pi.first_name,
    pi.last_name,
    pi.gender,
    pl.name AS city_name,
    COALESCE(f.friend_count, 0)                 AS friend_count,
    COALESCE(po.post_count, 0)                  AS post_count,
    COALESCE(co.comment_count, 0)               AS comment_count,
    COALESCE(lgp.likes_given_to_posts, 0)       AS likes_given_to_posts,
    COALESCE(lgc.likes_given_to_comments, 0)    AS likes_given_to_comments,
    COALESCE(lrp.likes_received_on_posts, 0)    AS likes_received_on_posts,
    COALESCE(lrc.likes_received_on_comments, 0) AS likes_received_on_comments
FROM person_info pi
LEFT JOIN friends f                ON f.person_id = pi.person_id
LEFT JOIN posts po                 ON po.person_id = pi.person_id
LEFT JOIN comments co              ON co.person_id = pi.person_id
LEFT JOIN likes_given_posts lgp    ON lgp.person_id = pi.person_id
LEFT JOIN likes_given_comments lgc ON lgc.person_id = pi.person_id
LEFT JOIN likes_received_posts lrp ON lrp.person_id = pi.person_id
LEFT JOIN likes_received_comments lrc ON lrc.person_id = pi.person_id
LEFT JOIN place pl                 ON pl.id = pi.location_city_id
ORDER BY friend_count DESC, post_count DESC
LIMIT 100
