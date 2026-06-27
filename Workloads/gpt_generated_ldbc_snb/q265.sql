WITH friends AS (
    SELECT person1_id AS person_id, person2_id AS friend_id
    FROM person_knows_person
    UNION ALL
    SELECT person2_id AS person_id, person1_id AS friend_id
    FROM person_knows_person
),
friend_counts AS (
    SELECT person_id, COUNT(DISTINCT friend_id) AS total_friends
    FROM friends
    GROUP BY person_id
),
like_counts AS (
    SELECT person_id, COUNT(post_id) AS likes_given
    FROM person_likes_post
    GROUP BY person_id
)
SELECT
    p.id AS person_id,
    p.first_name,
    p.last_name,
    p.gender,
    COALESCE(fc.total_friends, 0) AS total_friends,
    COALESCE(lc.likes_given, 0) AS likes_given,
    CASE
        WHEN COALESCE(lc.likes_given, 0) = 0 THEN NULL
        ELSE COALESCE(fc.total_friends, 0) * 1.0 / lc.likes_given
    END AS friends_per_like
FROM person p
LEFT JOIN friend_counts fc ON fc.person_id = p.id
LEFT JOIN like_counts lc ON lc.person_id = p.id
WHERE p.gender IS NOT NULL
ORDER BY friends_per_like DESC NULLS LAST, total_friends DESC
LIMIT 100
