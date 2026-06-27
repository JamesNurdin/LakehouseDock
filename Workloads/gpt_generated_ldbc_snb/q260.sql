-- Analytical query: employee activity and engagement per company
WITH employee_posts AS (
    SELECT
        pwac.company_id,
        pwac.person_id AS employee_id,
        p.id AS post_id,
        p.length AS post_length
    FROM person_work_at_company pwac
    JOIN person per
        ON pwac.person_id = per.id
    JOIN post p
        ON p.creator_person_id = per.id
)
SELECT
    ep.company_id,
    COUNT(DISTINCT ep.employee_id) AS employee_count,
    COUNT(DISTINCT ep.post_id) AS post_count,
    COALESCE(AVG(ep.post_length), 0) AS avg_post_length,
    COUNT(plp.person_id) AS total_likes_on_employee_posts,
    COUNT(DISTINCT psu.person_id) AS employees_with_university,
    COUNT(DISTINCT psu.university_id) AS distinct_universities_among_employees
FROM employee_posts ep
LEFT JOIN person_likes_post plp
    ON plp.post_id = ep.post_id
LEFT JOIN person_study_at_university psu
    ON psu.person_id = ep.employee_id
GROUP BY ep.company_id
ORDER BY employee_count DESC
LIMIT 10
