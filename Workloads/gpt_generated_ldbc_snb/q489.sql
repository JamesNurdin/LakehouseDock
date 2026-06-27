WITH org_employee_stats AS (
    SELECT
        o.id AS org_id,
        o.type AS org_type,
        o.name AS org_name,
        o.location_place_id,
        COUNT(p.person_id) AS employee_count,
        COUNT(DISTINCT p.person_id) AS distinct_employee_count,
        AVG(year(current_date) - p.work_from) AS avg_tenure,
        MIN(CAST(p.creation_date AS DATE)) AS earliest_creation_date,
        MAX(CAST(p.creation_date AS DATE)) AS latest_creation_date
    FROM
        organisation o
    JOIN
        person_work_at_company p
        ON p.company_id = o.id
    GROUP BY
        o.id,
        o.type,
        o.name,
        o.location_place_id
)
SELECT
    org_id,
    org_type,
    org_name,
    location_place_id,
    employee_count,
    distinct_employee_count,
    avg_tenure,
    earliest_creation_date,
    latest_creation_date
FROM org_employee_stats
WHERE employee_count > 10
ORDER BY employee_count DESC
LIMIT 20
