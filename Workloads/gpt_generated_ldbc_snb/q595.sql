WITH employee_university AS (
    SELECT
        pwac.company_id,
        pwac.person_id,
        pwac.work_from,
        psau.university_id,
        org_company.name AS company_name,
        org_university.name AS university_name,
        p.gender
    FROM person_work_at_company pwac
    JOIN organisation org_company
        ON pwac.company_id = org_company.id
    JOIN person p
        ON pwac.person_id = p.id
    JOIN person_study_at_university psau
        ON psau.person_id = p.id
    JOIN organisation org_university
        ON psau.university_id = org_university.id
    WHERE org_company.type = 'Company'
      AND org_university.type = 'University'
)
SELECT
    eu.company_id,
    eu.company_name,
    COUNT(DISTINCT eu.person_id) AS employee_count,
    AVG(eu.work_from) AS avg_work_start_year,
    COUNT(DISTINCT eu.university_id) AS distinct_universities,
    ARRAY_AGG(DISTINCT eu.university_name) AS university_list
FROM employee_university eu
GROUP BY eu.company_id, eu.company_name
ORDER BY employee_count DESC
LIMIT 10
