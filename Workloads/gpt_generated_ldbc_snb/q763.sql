WITH uni_stats AS (
    SELECT
        o.id,
        o.type,
        o.name,
        COUNT(DISTINCT ps.person_id) AS total_students,
        AVG(ps.class_year) AS avg_class_year
    FROM organisation o
    LEFT JOIN person_study_at_university ps
        ON ps.university_id = o.id
    GROUP BY o.id, o.type, o.name
),
comp_stats AS (
    SELECT
        o.id,
        o.type,
        o.name,
        COUNT(DISTINCT pw.person_id) AS total_employees,
        AVG(pw.work_from) AS avg_work_from
    FROM organisation o
    LEFT JOIN person_work_at_company pw
        ON pw.company_id = o.id
    GROUP BY o.id, o.type, o.name
)
SELECT
    COALESCE(u.id, c.id) AS organisation_id,
    COALESCE(u.type, c.type) AS organisation_type,
    COALESCE(u.name, c.name) AS organisation_name,
    u.total_students,
    u.avg_class_year,
    c.total_employees,
    c.avg_work_from,
    CAST(c.total_employees AS double) / NULLIF(u.total_students, 0) AS employee_to_student_ratio
FROM uni_stats u
FULL OUTER JOIN comp_stats c
    ON u.id = c.id
ORDER BY u.total_students DESC NULLS LAST, c.total_employees DESC NULLS LAST
