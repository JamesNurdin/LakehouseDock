WITH student_details AS (
    SELECT
        psu.university_id,
        o.name AS university_name,
        o.type AS university_type,
        pl_uni_loc.id AS uni_place_id,
        pl_uni_loc.name AS uni_place_name,
        pl_uni_parent.name AS uni_region_name,
        p.id AS person_id,
        p.gender,
        p.language,
        pl_city.id AS city_id,
        pl_city.name AS city_name,
        pl_city_parent.name AS city_region_name,
        psu.class_year
    FROM person_study_at_university psu
    JOIN person p ON psu.person_id = p.id
    JOIN organisation o ON psu.university_id = o.id
    JOIN place pl_uni_loc ON o.location_place_id = pl_uni_loc.id
    LEFT JOIN place pl_uni_parent ON pl_uni_loc.part_of_place_id = pl_uni_parent.id
    JOIN place pl_city ON p.location_city_id = pl_city.id
    LEFT JOIN place pl_city_parent ON pl_city.part_of_place_id = pl_city_parent.id
)
SELECT
    university_name,
    university_type,
    uni_place_name,
    uni_region_name,
    city_name,
    city_region_name,
    COUNT(DISTINCT person_id) AS student_count,
    AVG(class_year) AS avg_class_year,
    COUNT(DISTINCT CASE WHEN gender = 'male' THEN person_id END) AS male_students,
    COUNT(DISTINCT CASE WHEN gender = 'female' THEN person_id END) AS female_students
FROM student_details
GROUP BY
    university_name,
    university_type,
    uni_place_name,
    uni_region_name,
    city_name,
    city_region_name
ORDER BY student_count DESC
LIMIT 100
