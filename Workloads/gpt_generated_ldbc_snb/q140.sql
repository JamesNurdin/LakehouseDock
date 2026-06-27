WITH pw AS (
    SELECT
        person_id,
        company_id,
        work_from,
        creation_date
    FROM person_work_at_company
    WHERE work_from IS NOT NULL
)
SELECT
    org.id AS organization_id,
    org.name AS organization_name,
    org.type AS organization_type,
    COUNT(pw.person_id) AS employee_count,
    COUNT(DISTINCT pw.person_id) AS distinct_employee_count,
    AVG(pw.work_from) AS avg_work_from,
    MIN(pw.work_from) AS min_work_from,
    MAX(pw.work_from) AS max_work_from,
    MIN(pw.creation_date) AS earliest_creation_date,
    MAX(pw.creation_date) AS latest_creation_date
FROM pw
JOIN organisation AS org
    ON pw.company_id = org.id
GROUP BY org.id, org.name, org.type
ORDER BY employee_count DESC
LIMIT 10
