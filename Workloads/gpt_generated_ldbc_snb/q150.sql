/*
  Analytical query: total employees and average tenure per organization type
*/
WITH company_stats AS (
    SELECT
        company_id,
        COUNT(DISTINCT person_id) AS employee_count,
        SUM(work_from) AS total_work_from
    FROM person_work_at_company
    GROUP BY company_id
),
type_stats AS (
    SELECT
        o.type,
        SUM(cs.employee_count) AS total_employees,
        CASE
            WHEN SUM(cs.employee_count) > 0
            THEN SUM(cs.total_work_from) / SUM(cs.employee_count)
        END AS avg_work_from,
        COUNT(DISTINCT o.id) AS org_count
    FROM company_stats cs
    JOIN organisation o
        ON cs.company_id = o.id
    GROUP BY o.type
)
SELECT
    type,
    total_employees,
    avg_work_from,
    org_count
FROM type_stats
ORDER BY total_employees DESC
