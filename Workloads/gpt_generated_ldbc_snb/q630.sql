WITH org_location AS (
    SELECT
        o.id AS org_id,
        o.type AS org_type,
        o.name AS org_name,
        o.location_place_id,
        p.id AS loc_id,
        p.name AS loc_name,
        p.type AS loc_type,
        p.part_of_place_id AS loc_parent_id
    FROM organisation o
    JOIN place p
        ON o.location_place_id = p.id
),
employee_counts AS (
    SELECT
        pwc.company_id,
        COUNT(DISTINCT pwc.person_id) AS employee_cnt,
        AVG(pwc.work_from) AS avg_work_from
    FROM person_work_at_company pwc
    GROUP BY pwc.company_id
)
SELECT
    ol.org_type,
    rp.name AS region_name,
    SUM(ec.employee_cnt) AS total_employees,
    AVG(ec.avg_work_from) AS avg_start_year
FROM org_location ol
JOIN employee_counts ec
    ON ol.org_id = ec.company_id
LEFT JOIN place rp
    ON ol.loc_parent_id = rp.id
GROUP BY
    ol.org_type,
    rp.name
ORDER BY total_employees DESC
LIMIT 100
