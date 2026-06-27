WITH work_counts AS (
    SELECT
        o.id AS org_id,
        o.type AS org_type,
        o.name AS org_name,
        o.location_place_id,
        COUNT(pw.person_id) AS employee_count,
        COUNT(DISTINCT pw.person_id) AS distinct_employee_count,
        AVG(pw.work_from) AS avg_work_from,
        MIN(pw.creation_date) AS first_hire_date,
        MAX(pw.creation_date) AS latest_hire_date
    FROM organisation AS o
    JOIN person_work_at_company AS pw
        ON pw.company_id = o.id
    GROUP BY o.id, o.type, o.name, o.location_place_id
)
SELECT
    org_type,
    org_name,
    location_place_id,
    employee_count,
    distinct_employee_count,
    avg_work_from,
    first_hire_date,
    latest_hire_date
FROM work_counts
ORDER BY employee_count DESC
LIMIT 10
