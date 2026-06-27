-- Employees per organization region with local residency and gender breakdown
WITH employee_locations AS (
    SELECT
        pwac.person_id,
        pwac.company_id,
        pwac.work_from,
        p.gender,
        org_region.id   AS org_region_id,
        org_region.name AS org_region_name,
        person_region.id AS person_region_id
    FROM person_work_at_company pwac
    JOIN person p
        ON pwac.person_id = p.id
    JOIN organisation o
        ON pwac.company_id = o.id
    JOIN place org_city
        ON o.location_place_id = org_city.id
    JOIN place org_region
        ON org_city.part_of_place_id = org_region.id
    JOIN place person_city
        ON p.location_city_id = person_city.id
    JOIN place person_region
        ON person_city.part_of_place_id = person_region.id
)
SELECT
    el.org_region_id,
    el.org_region_name,
    COUNT(DISTINCT el.person_id)          AS total_employees,
    SUM(CASE WHEN el.person_region_id = el.org_region_id THEN 1 ELSE 0 END) AS local_employees,
    COUNT(DISTINCT el.company_id)         AS total_organisations,
    AVG(el.work_from)                     AS avg_start_year,
    SUM(CASE WHEN el.gender = 'male'   THEN 1 ELSE 0 END) AS male_employees,
    SUM(CASE WHEN el.gender = 'female' THEN 1 ELSE 0 END) AS female_employees
FROM employee_locations el
GROUP BY el.org_region_id, el.org_region_name
ORDER BY total_employees DESC
LIMIT 100
