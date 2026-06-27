WITH study AS (
    SELECT
        psu.person_id,
        psu.university_id,
        psu.class_year,
        uni.name AS university_name
    FROM person_study_at_university AS psu
    JOIN organisation AS uni
        ON psu.university_id = uni.id
    WHERE uni.type = 'university'
), work AS (
    SELECT
        pwc.person_id,
        pwc.company_id,
        pwc.work_from,
        comp.name AS company_name
    FROM person_work_at_company AS pwc
    JOIN organisation AS comp
        ON pwc.company_id = comp.id
    WHERE comp.type = 'company'
)
SELECT
    study.university_id,
    study.university_name,
    work.company_id,
    work.company_name,
    COUNT(DISTINCT study.person_id) AS person_count,
    AVG(study.class_year) AS avg_class_year,
    AVG(work.work_from) AS avg_work_from
FROM study
JOIN work
    ON study.person_id = work.person_id
GROUP BY
    study.university_id,
    study.university_name,
    work.company_id,
    work.company_name
ORDER BY person_count DESC
LIMIT 100
