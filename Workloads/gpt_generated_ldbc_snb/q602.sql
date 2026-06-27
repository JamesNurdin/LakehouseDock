WITH person_first_job AS (
    SELECT
        pw.person_id,
        MIN(pw.work_from) AS first_work_from,
        p.gender
    FROM person_work_at_company pw
    JOIN person p
        ON pw.person_id = p.id
    GROUP BY pw.person_id, p.gender
)
SELECT
    o.id AS org_id,
    o.name AS org_name,
    o.type AS org_type,
    o.location_place_id AS org_location,
    COUNT(DISTINCT pw.person_id) AS employee_count,
    COUNT_IF(p.gender = 'male') AS male_employee_count,
    COUNT_IF(p.gender = 'female') AS female_employee_count,
    AVG(pw.work_from) AS avg_start_year,
    MIN(pw.work_from) AS earliest_start_year,
    MAX(pw.work_from) AS latest_start_year,
    APPROX_PERCENTILE(pw.work_from, 0.5) AS median_start_year,
    AVG(pf.first_work_from) AS avg_first_job_year,
    COUNT_IF(pf.first_work_from < pw.work_from) AS employees_with_later_start_year
FROM organisation o
JOIN person_work_at_company pw
    ON pw.company_id = o.id
JOIN person p
    ON pw.person_id = p.id
JOIN person_first_job pf
    ON pf.person_id = pw.person_id
WHERE o.type = 'Company'
GROUP BY
    o.id,
    o.name,
    o.type,
    o.location_place_id
ORDER BY employee_count DESC
LIMIT 50
