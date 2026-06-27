WITH university_students AS (
    SELECT
        psu.person_id,
        loc.id AS place_id,
        loc.name AS place_name,
        parent.id AS region_id,
        parent.name AS region_name,
        psu.class_year
    FROM person_study_at_university psu
    JOIN organisation org
        ON psu.university_id = org.id
    JOIN place loc
        ON org.location_place_id = loc.id
    LEFT JOIN place parent
        ON loc.part_of_place_id = parent.id
    WHERE org.type = 'university'
),
company_employees AS (
    SELECT
        pwa.person_id,
        loc.id AS place_id,
        loc.name AS place_name,
        parent.id AS region_id,
        parent.name AS region_name,
        pwa.work_from
    FROM person_work_at_company pwa
    JOIN organisation org
        ON pwa.company_id = org.id
    JOIN place loc
        ON org.location_place_id = loc.id
    LEFT JOIN place parent
        ON loc.part_of_place_id = parent.id
    WHERE org.type = 'company'
),
student_counts AS (
    SELECT
        region_id,
        region_name,
        COUNT(DISTINCT person_id) AS student_cnt,
        AVG(class_year) AS avg_class_year
    FROM university_students
    GROUP BY region_id, region_name
),
employee_counts AS (
    SELECT
        region_id,
        region_name,
        COUNT(DISTINCT person_id) AS employee_cnt,
        AVG(work_from) AS avg_work_from
    FROM company_employees
    GROUP BY region_id, region_name
),
overlap_counts AS (
    SELECT
        us.region_id,
        us.region_name,
        COUNT(DISTINCT us.person_id) AS overlap_cnt
    FROM university_students us
    JOIN company_employees ce
        ON us.person_id = ce.person_id
        AND us.region_id = ce.region_id
    GROUP BY us.region_id, us.region_name
)
SELECT
    COALESCE(sc.region_id, ec.region_id, oc.region_id) AS region_id,
    COALESCE(sc.region_name, ec.region_name, oc.region_name) AS region_name,
    COALESCE(sc.student_cnt, 0) AS student_cnt,
    COALESCE(sc.avg_class_year, 0) AS avg_class_year,
    COALESCE(ec.employee_cnt, 0) AS employee_cnt,
    COALESCE(ec.avg_work_from, 0) AS avg_work_from,
    COALESCE(oc.overlap_cnt, 0) AS overlap_cnt
FROM student_counts sc
FULL OUTER JOIN employee_counts ec
    ON sc.region_id = ec.region_id
FULL OUTER JOIN overlap_counts oc
    ON COALESCE(sc.region_id, ec.region_id) = oc.region_id
ORDER BY student_cnt DESC
LIMIT 50
