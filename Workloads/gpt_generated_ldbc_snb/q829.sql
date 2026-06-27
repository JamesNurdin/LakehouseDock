/*
  Analytical query: number of students per university, gender split, average class year,
  and ranking of universities by total student count.
*/
WITH uni_agg AS (
    SELECT
        o.id   AS university_id,
        o.name AS university_name,
        COUNT(*)                                 AS total_students,
        AVG(psau.class_year)                     AS avg_class_year,
        COUNT(CASE WHEN p.gender = 'male'   THEN 1 END) AS male_students,
        COUNT(CASE WHEN p.gender = 'female' THEN 1 END) AS female_students
    FROM person_study_at_university psau
    JOIN person p
        ON psau.person_id = p.id
    JOIN organisation o
        ON psau.university_id = o.id
    WHERE o.type = 'University'
    GROUP BY o.id, o.name
)
SELECT
    university_id,
    university_name,
    total_students,
    avg_class_year,
    male_students,
    female_students,
    RANK() OVER (ORDER BY total_students DESC) AS university_rank
FROM uni_agg
ORDER BY total_students DESC
LIMIT 10
