WITH student_comments AS (
    SELECT
        u.id AS university_id,
        u.name AS university_name,
        c.id AS comment_id,
        c.length AS comment_length,
        p_student.id AS student_id
    FROM person_study_at_university s
    JOIN person p_student
        ON s.person_id = p_student.id
    JOIN organisation u
        ON s.university_id = u.id
    JOIN comment c
        ON c.creator_person_id = p_student.id
    JOIN post po
        ON c.parent_post_id = po.id
    JOIN place pl_univ_loc
        ON u.location_place_id = pl_univ_loc.id
    JOIN place pl_post_loc
        ON po.location_country_id = pl_post_loc.id
    WHERE pl_univ_loc.id = pl_post_loc.id
)
SELECT
    university_id,
    university_name,
    COUNT(comment_id) AS comment_count,
    COUNT(DISTINCT student_id) AS distinct_student_count,
    SUM(comment_length) AS total_comment_length,
    AVG(comment_length) AS avg_comment_length
FROM student_comments
GROUP BY university_id, university_name
ORDER BY comment_count DESC
LIMIT 10
