WITH gender_stats AS (
    SELECT
        psu.university_id,
        p.gender,
        COUNT(*) AS gender_cnt,
        AVG(psu.class_year) AS avg_class_year,
        MIN(psu.class_year) AS min_class_year,
        MAX(psu.class_year) AS max_class_year
    FROM person p
    JOIN person_study_at_university psu
        ON psu.person_id = p.id
    WHERE psu.class_year >= 2000
    GROUP BY psu.university_id, p.gender
)
SELECT
    university_id,
    gender,
    gender_cnt,
    avg_class_year,
    min_class_year,
    max_class_year,
    gender_cnt * 100.0 / SUM(gender_cnt) OVER (PARTITION BY university_id) AS gender_pct
FROM gender_stats
ORDER BY university_id, gender
