WITH uni_students AS (
    SELECT
        o.id AS university_id,
        o.name AS university_name,
        o.location_place_id AS university_place_id,
        p.id AS person_id,
        p.gender,
        p.location_city_id AS person_city_id,
        psu.class_year
    FROM person_study_at_university psu
    JOIN person p ON psu.person_id = p.id
    JOIN organisation o ON psu.university_id = o.id
    WHERE o.type = 'university'
)
SELECT
    us.university_id,
    us.university_name,
    uc.name AS university_city,
    rp.name AS university_region,
    COUNT(*) AS student_count,
    AVG(us.class_year) AS avg_class_year,
    SUM(CASE WHEN us.person_city_id = us.university_place_id THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS pct_students_local,
    SUM(CASE WHEN us.gender = 'male' THEN 1 ELSE 0 END) AS male_students,
    SUM(CASE WHEN us.gender = 'female' THEN 1 ELSE 0 END) AS female_students
FROM uni_students us
JOIN place uc ON us.university_place_id = uc.id
LEFT JOIN place rp ON uc.part_of_place_id = rp.id
GROUP BY us.university_id, us.university_name, uc.name, rp.name
ORDER BY student_count DESC
LIMIT 10
