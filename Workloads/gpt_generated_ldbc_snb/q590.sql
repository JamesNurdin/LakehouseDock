WITH uni_students AS (
    SELECT
        o.id AS university_id,
        o.name AS university_name,
        o.url AS university_url,
        l.name AS location_name,
        p_parent.name AS region_name,
        psau.class_year,
        COUNT(DISTINCT psau.person_id) AS student_count
    FROM person_study_at_university psau
    JOIN organisation o
        ON psau.university_id = o.id
    JOIN place l
        ON o.location_place_id = l.id
    LEFT JOIN place p_parent
        ON l.part_of_place_id = p_parent.id
    WHERE o.type = 'university'
    GROUP BY
        o.id,
        o.name,
        o.url,
        l.name,
        p_parent.name,
        psau.class_year
)
SELECT
    university_id,
    university_name,
    university_url,
    location_name,
    region_name,
    class_year,
    student_count
FROM uni_students
ORDER BY student_count DESC, university_name, class_year
