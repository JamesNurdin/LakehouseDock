WITH org_employee AS (
    SELECT
        o.id AS org_id,
        o.type AS org_type,
        o.name AS org_name,
        p.gender,
        pwc.work_from
    FROM organisation o
    JOIN person_work_at_company pwc
        ON pwc.company_id = o.id
    JOIN person p
        ON p.id = pwc.person_id
)
SELECT
    org_id,
    org_type,
    org_name,
    COUNT(*) AS total_employees,
    COUNT(CASE WHEN gender = 'male' THEN 1 END) AS male_employees,
    COUNT(CASE WHEN gender = 'female' THEN 1 END) AS female_employees,
    AVG(work_from) AS avg_start_year,
    MIN(work_from) AS earliest_start_year,
    MAX(work_from) AS latest_start_year
FROM org_employee
GROUP BY org_id, org_type, org_name
ORDER BY total_employees DESC
LIMIT 10
