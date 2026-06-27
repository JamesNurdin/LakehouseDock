WITH friend_counts AS (
    SELECT person_id, COUNT(*) AS friend_count
    FROM (
        SELECT person1_id AS person_id FROM person_knows_person
        UNION ALL
        SELECT person2_id AS person_id FROM person_knows_person
    ) AS all_friends
    GROUP BY person_id
),

employee_data AS (
    SELECT
        p.id AS person_id,
        o.id AS org_id,
        o.name AS org_name,
        o.type AS org_type,
        pwc.work_from AS work_start_year,
        COALESCE(fc.friend_count, 0) AS friend_count
    FROM person_work_at_company pwc
    JOIN person p ON pwc.person_id = p.id
    JOIN organisation o ON pwc.company_id = o.id
    LEFT JOIN friend_counts fc ON p.id = fc.person_id
),

student_data AS (
    SELECT
        p.id AS person_id,
        o.id AS org_id,
        o.name AS org_name,
        o.type AS org_type,
        psu.class_year,
        COALESCE(fc.friend_count, 0) AS friend_count
    FROM person_study_at_university psu
    JOIN person p ON psu.person_id = p.id
    JOIN organisation o ON psu.university_id = o.id
    LEFT JOIN friend_counts fc ON p.id = fc.person_id
),

moderator_data AS (
    SELECT
        f.id AS forum_id,
        o.id AS org_id,
        o.name AS org_name,
        o.type AS org_type
    FROM forum f
    JOIN person p ON f.moderator_person_id = p.id
    JOIN person_work_at_company pwc ON p.id = pwc.person_id
    JOIN organisation o ON pwc.company_id = o.id
)
SELECT
    org.id,
    org.name,
    org.type,
    COUNT(DISTINCT emp.person_id) AS num_employees,
    AVG(emp.work_start_year) AS avg_work_start_year,
    AVG(emp.friend_count) AS avg_employee_friends,
    COUNT(DISTINCT stu.person_id) AS num_students,
    AVG(stu.class_year) AS avg_student_class_year,
    AVG(stu.friend_count) AS avg_student_friends,
    COUNT(DISTINCT mod.forum_id) AS num_moderated_forums
FROM organisation org
LEFT JOIN employee_data emp ON org.id = emp.org_id
LEFT JOIN student_data stu ON org.id = stu.org_id
LEFT JOIN moderator_data mod ON org.id = mod.org_id
GROUP BY org.id, org.name, org.type
ORDER BY num_employees DESC
LIMIT 10
