WITH friend_counts AS (
    SELECT person_id, COUNT(*) AS friend_cnt
    FROM (
        SELECT person1_id AS person_id FROM person_knows_person
        UNION ALL
        SELECT person2_id AS person_id FROM person_knows_person
    ) AS all_friends
    GROUP BY person_id
),
students AS (
    SELECT psu.university_id, p.id AS person_id
    FROM person_study_at_university psu
    JOIN person p ON psu.person_id = p.id
)
SELECT
    o.id AS university_id,
    o.name AS university_name,
    COUNT(*) AS student_count,
    AVG(COALESCE(fc.friend_cnt, 0)) AS avg_friends_per_student
FROM students s
JOIN organisation o ON s.university_id = o.id
LEFT JOIN friend_counts fc ON s.person_id = fc.person_id
GROUP BY o.id, o.name
ORDER BY avg_friends_per_student DESC
LIMIT 10
