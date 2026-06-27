-- Analytical query: total students per university with average class year and ranking
WITH uni_stats AS (
    SELECT
        ps.university_id,
        COUNT(p.id) AS total_students,
        AVG(ps.class_year) AS avg_class_year,
        MIN(p.creation_date) AS earliest_creation,
        MAX(p.creation_date) AS latest_creation
    FROM person p
    JOIN person_study_at_university ps
        ON p.id = ps.person_id
    GROUP BY ps.university_id
)
SELECT
    university_id,
    total_students,
    avg_class_year,
    earliest_creation,
    latest_creation,
    RANK() OVER (ORDER BY total_students DESC) AS university_rank
FROM uni_stats
ORDER BY university_rank
