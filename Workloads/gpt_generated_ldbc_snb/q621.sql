WITH person_city AS (
    SELECT p.id AS person_id,
           p.location_city_id,
           pl.name AS city_name
    FROM person p
    JOIN place pl ON p.location_city_id = pl.id
),

person_study_agg AS (
    SELECT pc.person_id,
           COUNT(DISTINCT psu.university_id) AS uni_cnt,
           AVG(psu.class_year) AS avg_class_year,
           SUM(CASE WHEN uni_loc.id = pc.location_city_id THEN 1 ELSE 0 END) AS study_in_res_city
    FROM person_city pc
    JOIN person_study_at_university psu ON pc.person_id = psu.person_id
    JOIN organisation uni_org ON psu.university_id = uni_org.id
    JOIN place uni_loc ON uni_org.location_place_id = uni_loc.id
    GROUP BY pc.person_id, pc.location_city_id
),

person_work_agg AS (
    SELECT pc.person_id,
           COUNT(DISTINCT pwc.company_id) AS comp_cnt,
           AVG(pwc.work_from) AS avg_work_from,
           SUM(CASE WHEN comp_loc.id = pc.location_city_id THEN 1 ELSE 0 END) AS work_in_res_city
    FROM person_city pc
    JOIN person_work_at_company pwc ON pc.person_id = pwc.person_id
    JOIN organisation comp_org ON pwc.company_id = comp_org.id
    JOIN place comp_loc ON comp_org.location_place_id = comp_loc.id
    GROUP BY pc.person_id, pc.location_city_id
)

SELECT
    pc.city_name,
    COUNT(DISTINCT pc.person_id) AS resident_persons,
    SUM(COALESCE(psa.uni_cnt, 0)) AS total_universities_attended,
    SUM(COALESCE(pwa.comp_cnt, 0)) AS total_companies_worked,
    AVG(psa.avg_class_year) AS avg_class_year_per_person,
    AVG(pwa.avg_work_from) AS avg_work_from_per_person,
    SUM(COALESCE(psa.study_in_res_city, 0)) AS total_studies_in_res_city,
    SUM(COALESCE(pwa.work_in_res_city, 0)) AS total_works_in_res_city
FROM person_city pc
LEFT JOIN person_study_agg psa ON pc.person_id = psa.person_id
LEFT JOIN person_work_agg pwa ON pc.person_id = pwa.person_id
GROUP BY pc.city_name
ORDER BY resident_persons DESC
LIMIT 10
