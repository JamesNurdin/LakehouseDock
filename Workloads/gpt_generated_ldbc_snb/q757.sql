WITH employee_comments AS (
    SELECT
        org.id AS company_id,
        org.name AS company_name,
        comp_place.name AS company_location_name,
        p.id AS employee_id,
        p.first_name,
        p.last_name,
        COUNT(c.id) AS comment_count
    FROM person p
    JOIN person_work_at_company pwc
        ON pwc.person_id = p.id
    JOIN organisation org
        ON org.id = pwc.company_id
    LEFT JOIN comment c
        ON c.creator_person_id = p.id
    LEFT JOIN place comp_place
        ON org.location_place_id = comp_place.id
    WHERE org.type = 'company'
    GROUP BY org.id, org.name, comp_place.name, p.id, p.first_name, p.last_name
), employee_ranking AS (
    SELECT
        company_id,
        company_name,
        company_location_name,
        employee_id,
        first_name,
        last_name,
        comment_count,
        ROW_NUMBER() OVER (PARTITION BY company_id ORDER BY comment_count DESC) AS employee_rank
    FROM employee_comments
)
SELECT
    er.company_id,
    er.company_name,
    er.company_location_name,
    COUNT(DISTINCT er.employee_id) AS employee_count,
    SUM(er.comment_count) AS total_comments,
    CASE WHEN COUNT(DISTINCT er.employee_id) = 0 THEN 0
         ELSE CAST(SUM(er.comment_count) AS double) / COUNT(DISTINCT er.employee_id)
    END AS avg_comments_per_employee,
    MAX(CASE WHEN er.employee_rank = 1 THEN er.first_name || ' ' || er.last_name END) AS top_employee_name,
    MAX(CASE WHEN er.employee_rank = 1 THEN er.comment_count END) AS top_employee_comment_count
FROM employee_ranking er
WHERE er.employee_rank <= 5
GROUP BY er.company_id, er.company_name, er.company_location_name
ORDER BY total_comments DESC
LIMIT 10
