/*
   Analytical query: For each company (organisation of type 'Company'), compute the number of distinct employees who have posted comments, the total number of comments they posted, and comment‑length statistics.
   The query joins comment → person → person_work_at_company → organisation and aggregates per organisation.
*/
WITH employee_comments AS (
    SELECT
        c.id                     AS comment_id,
        c.length                 AS comment_length,
        p.id                     AS person_id,
        pwc.company_id           AS company_id,
        org.id                   AS organization_id,
        org.name                 AS organization_name,
        org.type                 AS organization_type
    FROM comment AS c
    JOIN person AS p
        ON c.creator_person_id = p.id
    JOIN person_work_at_company AS pwc
        ON p.id = pwc.person_id
    JOIN organisation AS org
        ON pwc.company_id = org.id
)
SELECT
    ec.organization_id,
    ec.organization_name,
    ec.organization_type,
    COUNT(DISTINCT ec.person_id)        AS num_employees,
    COUNT(ec.comment_id)                AS total_comments,
    AVG(ec.comment_length)              AS avg_comment_length,
    MIN(ec.comment_length)              AS min_comment_length,
    MAX(ec.comment_length)              AS max_comment_length
FROM employee_comments AS ec
GROUP BY
    ec.organization_id,
    ec.organization_name,
    ec.organization_type
ORDER BY total_comments DESC
LIMIT 10
