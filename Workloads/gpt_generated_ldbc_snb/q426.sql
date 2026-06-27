WITH employees_by_company AS (
    SELECT
        w.company_id,
        COUNT(DISTINCT w.person_id) AS employee_count,
        AVG(w.work_from) AS avg_work_from,
        COUNT(DISTINCT CASE WHEN p.gender = 'male' THEN p.id END) AS male_employee_count,
        COUNT(DISTINCT CASE WHEN p.gender = 'female' THEN p.id END) AS female_employee_count
    FROM person_work_at_company w
    JOIN person p ON w.person_id = p.id
    GROUP BY w.company_id
),
internal_friendships AS (
    SELECT
        w1.company_id,
        COUNT(*) AS internal_friendship_count
    FROM person_knows_person kp
    JOIN person p1 ON kp.person1_id = p1.id
    JOIN person_work_at_company w1 ON p1.id = w1.person_id
    JOIN person p2 ON kp.person2_id = p2.id
    JOIN person_work_at_company w2 ON p2.id = w2.person_id
    WHERE w1.company_id = w2.company_id
    GROUP BY w1.company_id
)
SELECT
    o.id AS organisation_id,
    o.type AS organisation_type,
    o.name AS organisation_name,
    e.employee_count,
    e.avg_work_from,
    e.male_employee_count,
    e.female_employee_count,
    COALESCE(f.internal_friendship_count, 0) AS internal_friendship_count
FROM employees_by_company e
JOIN organisation o ON e.company_id = o.id
LEFT JOIN internal_friendships f ON e.company_id = f.company_id
WHERE o.type = 'Company'
ORDER BY e.employee_count DESC
LIMIT 10
