WITH resident AS (
    SELECT p.id AS person_id,
           pc.id AS city_id,
           pc.name AS city_name
    FROM person p
    JOIN place pc ON p.location_city_id = pc.id
),

employee AS (
    SELECT pwac.person_id,
           pc.id AS city_id,
           pwac.work_from
    FROM person_work_at_company pwac
    JOIN organisation oc ON pwac.company_id = oc.id
    JOIN place pc ON oc.location_place_id = pc.id
    WHERE oc.type = 'Company'
),

alumni AS (
    SELECT psu.person_id,
           pc.id AS city_id,
           psu.class_year
    FROM person_study_at_university psu
    JOIN organisation ou ON psu.university_id = ou.id
    JOIN place pc ON ou.location_place_id = pc.id
    WHERE ou.type = 'University'
)

SELECT r.city_id,
       r.city_name,
       COUNT(DISTINCT r.person_id) AS resident_count,
       COUNT(DISTINCT e.person_id) AS employee_count_same_city,
       AVG(2025 - e.work_from) AS avg_tenure_years,
       COUNT(DISTINCT a.person_id) AS alumni_count_same_city,
       AVG(a.class_year) AS avg_alumni_class_year
FROM resident r
LEFT JOIN employee e
    ON e.person_id = r.person_id
   AND e.city_id = r.city_id
LEFT JOIN alumni a
    ON a.person_id = r.person_id
   AND a.city_id = r.city_id
GROUP BY r.city_id, r.city_name
ORDER BY resident_count DESC
LIMIT 20
