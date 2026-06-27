WITH employee_comments AS (
    SELECT
        o.id AS org_id,
        o.name AS org_name,
        p.id AS person_id,
        p.first_name,
        p.last_name,
        c.id AS comment_id,
        c.length AS comment_length,
        pc.id AS comment_country_id,
        pc.name AS comment_country_name
    FROM comment c
    JOIN person p ON c.creator_person_id = p.id
    JOIN person_work_at_company pwc ON p.id = pwc.person_id
    JOIN organisation o ON pwc.company_id = o.id
    LEFT JOIN place pc ON c.location_country_id = pc.id
    WHERE c.length > 0
)
SELECT
    org_id,
    org_name,
    COUNT(comment_id) AS total_comments,
    AVG(comment_length) AS avg_comment_length,
    COUNT(DISTINCT person_id) AS distinct_commenters,
    COUNT(DISTINCT comment_country_name) AS distinct_countries_commented
FROM employee_comments
GROUP BY 1, 2
ORDER BY total_comments DESC
LIMIT 10
