/*
  Analytical query: for each university, compute total distinct students, the number of students enrolled in class year 2023,
  distinct class years represented, average class year, and the range of enrollment creation dates.
  Results are limited to the top 10 universities by total student count.
*/
WITH university_student_stats AS (
    SELECT
        ps.university_id,
        COUNT(DISTINCT ps.person_id) AS student_count,
        COUNT(DISTINCT CASE WHEN ps.class_year = 2023 THEN ps.person_id END) AS class_2023_count,
        COUNT(DISTINCT ps.class_year) AS distinct_class_years,
        AVG(ps.class_year) AS avg_class_year,
        MIN(ps.creation_date) AS earliest_enrollment,
        MAX(ps.creation_date) AS latest_enrollment
    FROM person_study_at_university ps
    GROUP BY ps.university_id
)
SELECT
    o.id AS university_id,
    o.name AS university_name,
    o.type AS university_type,
    o.location_place_id,
    uss.student_count,
    uss.class_2023_count,
    uss.distinct_class_years,
    uss.avg_class_year,
    uss.earliest_enrollment,
    uss.latest_enrollment
FROM university_student_stats uss
JOIN organisation o
    ON uss.university_id = o.id
WHERE o.type = 'University'
ORDER BY uss.student_count DESC
LIMIT 10
