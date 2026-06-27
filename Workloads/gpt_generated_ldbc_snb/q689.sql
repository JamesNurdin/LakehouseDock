WITH friend_counts AS (
    -- Count each outgoing friendship (person1 -> person2)
    SELECT person1_id AS person_id, COUNT(*) AS cnt
    FROM person_knows_person
    GROUP BY person1_id
    UNION ALL
    -- Count each incoming friendship (person2 -> person1)
    SELECT person2_id AS person_id, COUNT(*) AS cnt
    FROM person_knows_person
    GROUP BY person2_id
),
total_friends AS (
    -- Sum outgoing and incoming counts to get total friends per person
    SELECT person_id, SUM(cnt) AS total_friends
    FROM friend_counts
    GROUP BY person_id
),
likes_counts AS (
    -- Number of comments liked by each person
    SELECT person_id, COUNT(*) AS liked_comments
    FROM person_likes_comment
    GROUP BY person_id
)
SELECT
    p.gender,
    COUNT(DISTINCT p.id) AS person_count,
    AVG(COALESCE(tf.total_friends, 0)) AS avg_friends,
    AVG(COALESCE(lc.liked_comments, 0)) AS avg_liked_comments
FROM person p
LEFT JOIN total_friends tf ON tf.person_id = p.id
LEFT JOIN likes_counts lc ON lc.person_id = p.id
WHERE p.gender IS NOT NULL
GROUP BY p.gender
ORDER BY avg_friends DESC
