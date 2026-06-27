WITH friend_edges AS (
    SELECT person1_id AS person_id, person2_id AS friend_id
    FROM person_knows_person
    UNION ALL
    SELECT person2_id AS person_id, person1_id AS friend_id
    FROM person_knows_person
),
friend_counts AS (
    SELECT person_id, COUNT(DISTINCT friend_id) AS friend_count
    FROM friend_edges
    GROUP BY person_id
)
SELECT
    p.gender,
    COUNT(DISTINCT p.id) AS num_people,
    AVG(c.length) AS avg_comment_length,
    SUM(c.length) AS total_comment_length,
    COUNT(c.id) AS total_comments
FROM person p
JOIN friend_counts fc
    ON p.id = fc.person_id
JOIN comment c
    ON c.creator_person_id = p.id
WHERE fc.friend_count >= 5
GROUP BY p.gender
ORDER BY avg_comment_length DESC
