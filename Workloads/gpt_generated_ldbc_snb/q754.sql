WITH friends AS (
    SELECT person1_id AS person_id, person2_id AS friend_id
    FROM person_knows_person
    UNION ALL
    SELECT person2_id AS person_id, person1_id AS friend_id
    FROM person_knows_person
),
friend_counts AS (
    SELECT person_id, COUNT(DISTINCT friend_id) AS friend_cnt
    FROM friends
    GROUP BY person_id
),
likes_given AS (
    SELECT person_id, COUNT(*) AS likes_given_cnt
    FROM person_likes_post
    GROUP BY person_id
),
likes_received AS (
    SELECT
        p.creator_person_id AS person_id,
        COUNT(plp.post_id) AS likes_received_cnt,
        AVG(p.length) FILTER (WHERE plp.post_id IS NOT NULL) AS avg_liked_post_length
    FROM post p
    LEFT JOIN person_likes_post plp
        ON plp.post_id = p.id
    GROUP BY p.creator_person_id
),
person_aggregates AS (
    SELECT
        per.id,
        per.first_name,
        per.last_name,
        COALESCE(fc.friend_cnt, 0) AS friend_cnt,
        COALESCE(lg.likes_given_cnt, 0) AS likes_given_cnt,
        COALESCE(lr.likes_received_cnt, 0) AS likes_received_cnt,
        COALESCE(lr.avg_liked_post_length, 0) AS avg_liked_post_length
    FROM person per
    LEFT JOIN friend_counts fc
        ON fc.person_id = per.id
    LEFT JOIN likes_given lg
        ON lg.person_id = per.id
    LEFT JOIN likes_received lr
        ON lr.person_id = per.id
)
SELECT
    id,
    first_name,
    last_name,
    friend_cnt,
    likes_given_cnt,
    likes_received_cnt,
    avg_liked_post_length
FROM person_aggregates
ORDER BY likes_received_cnt DESC, friend_cnt DESC
LIMIT 10
