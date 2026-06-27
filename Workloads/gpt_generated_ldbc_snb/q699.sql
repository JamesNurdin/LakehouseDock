WITH uni_stats AS (
    SELECT
        o.id AS university_id,
        o.name AS university_name,
        o.location_place_id,
        COUNT(DISTINCT ps.person_id) AS student_count,
        AVG(ps.class_year) AS avg_class_year,
        MIN(ps.creation_date) AS first_study_date,
        MAX(ps.creation_date) AS latest_study_date
    FROM person_study_at_university ps
    JOIN organisation o
      ON ps.university_id = o.id
    WHERE o.type = 'University'
    GROUP BY
        o.id,
        o.name,
        o.location_place_id
)
SELECT
    university_id,
    university_name,
    student_count,
    avg_class_year,
    first_study_date,
    latest_study_date,
    RANK() OVER (ORDER BY student_count DESC) AS university_rank
FROM uni_stats
ORDER BY student_count DESC
LIMIT 10
