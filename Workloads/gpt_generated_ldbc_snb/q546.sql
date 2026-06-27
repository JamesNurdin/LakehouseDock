WITH student_info AS (
    SELECT
        p.id AS person_id,
        p.gender,
        p.birthday,
        psa.university_id,
        psa.class_year
    FROM person p
    JOIN person_study_at_university psa
        ON psa.person_id = p.id
)
SELECT
    o.id AS university_id,
    o.name AS university_name,
    COUNT(*) AS total_students,
    COUNT(CASE WHEN si.gender = 'male' THEN 1 END) AS male_students,
    COUNT(CASE WHEN si.gender = 'female' THEN 1 END) AS female_students,
    AVG(date_diff('year', CAST(si.birthday AS date), current_date)) AS avg_student_age,
    MIN(si.class_year) AS min_class_year,
    MAX(si.class_year) AS max_class_year
FROM student_info si
JOIN organisation o
    ON si.university_id = o.id
WHERE si.class_year >= 2015
GROUP BY o.id, o.name
ORDER BY total_students DESC
LIMIT 10
