WITH student_comments AS (
    SELECT
        p.id AS person_id,
        s.university_id,
        c.id AS comment_id,
        c.length AS comment_length
    FROM person p
    JOIN person_study_at_university s ON s.person_id = p.id
    JOIN comment c ON c.creator_person_id = p.id
),
student_friends AS (
    SELECT
        f.university_id,
        f.person_id,
        COUNT(DISTINCT f.friend_id) AS friend_count
    FROM (
        SELECT
            p.id AS person_id,
            pkp.person2_id AS friend_id,
            s.university_id
        FROM person_knows_person pkp
        JOIN person p ON p.id = pkp.person1_id
        JOIN person_study_at_university s ON s.person_id = p.id
        UNION ALL
        SELECT
            p.id AS person_id,
            pkp.person1_id AS friend_id,
            s.university_id
        FROM person_knows_person pkp
        JOIN person p ON p.id = pkp.person2_id
        JOIN person_study_at_university s ON s.person_id = p.id
    ) f
    GROUP BY f.university_id, f.person_id
)
SELECT
    o.name AS university_name,
    COUNT(DISTINCT sc.person_id) AS num_students,
    COUNT(sc.comment_id) AS total_comments,
    AVG(sc.comment_length) AS avg_comment_length,
    COUNT(lc.comment_id) AS total_likes,
    ROUND(COUNT(lc.comment_id) * 1.0 / NULLIF(COUNT(sc.comment_id), 0), 2) AS avg_likes_per_comment,
    AVG(sf.friend_count) AS avg_friends_per_student
FROM student_comments sc
JOIN organisation o ON o.id = sc.university_id
LEFT JOIN person_likes_comment lc ON lc.comment_id = sc.comment_id
LEFT JOIN student_friends sf ON sf.person_id = sc.person_id
WHERE o.type = 'University'
GROUP BY o.name
ORDER BY total_likes DESC
LIMIT 10
