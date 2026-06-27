WITH uni_stats AS (
    SELECT
        o.id AS organisation_id,
        o.type AS organisation_type,
        o.name AS organisation_name,
        COUNT(*) AS total_study_records,
        COUNT(DISTINCT ps.person_id) AS distinct_students,
        AVG(ps.class_year) AS avg_class_year
    FROM person_study_at_university ps
    JOIN organisation o
        ON ps.university_id = o.id
    GROUP BY o.id, o.type, o.name
),
comp_stats AS (
    SELECT
        o.id AS organisation_id,
        o.type AS organisation_type,
        o.name AS organisation_name,
        COUNT(*) AS total_work_records,
        COUNT(DISTINCT pw.person_id) AS distinct_employees,
        AVG(pw.work_from) AS avg_work_start_year
    FROM person_work_at_company pw
    JOIN organisation o
        ON pw.company_id = o.id
    GROUP BY o.id, o.type, o.name
)
SELECT
    COALESCE(u.organisation_id, c.organisation_id) AS organisation_id,
    COALESCE(u.organisation_type, c.organisation_type) AS organisation_type,
    COALESCE(u.organisation_name, c.organisation_name) AS organisation_name,
    u.distinct_students,
    u.avg_class_year,
    c.distinct_employees,
    c.avg_work_start_year,
    CASE
        WHEN c.distinct_employees = 0 THEN NULL
        ELSE u.distinct_students * 1.0 / c.distinct_employees
    END AS student_to_employee_ratio
FROM uni_stats u
FULL OUTER JOIN comp_stats c
    ON u.organisation_id = c.organisation_id
WHERE COALESCE(u.organisation_type, c.organisation_type) IN ('university', 'company')
ORDER BY student_to_employee_ratio DESC NULLS LAST
LIMIT 100
