WITH person_age AS (
    SELECT
        id,
        gender,
        CAST(birthday AS date) AS birth_date,
        date_diff('year', CAST(birthday AS date), current_date) AS age
    FROM person
),
joined AS (
    SELECT
        psu.university_id,
        pa.gender,
        psu.class_year,
        pa.age
    FROM person_study_at_university psu
    JOIN person_age pa
        ON psu.person_id = pa.id
),
agg AS (
    SELECT
        j.university_id,
        j.gender,
        COUNT(*) AS gender_student_count,
        AVG(j.class_year) AS avg_class_year,
        AVG(j.age) AS avg_age
    FROM joined j
    GROUP BY j.university_id, j.gender
)
SELECT
    a.university_id,
    a.gender,
    a.gender_student_count,
    a.avg_class_year,
    a.avg_age,
    SUM(a.gender_student_count) OVER (PARTITION BY a.university_id) AS total_student_count,
    (a.gender_student_count * 1.0 / SUM(a.gender_student_count) OVER (PARTITION BY a.university_id)) AS gender_proportion
FROM agg a
ORDER BY a.university_id, a.gender_student_count DESC
