WITH employee_comments AS (
    SELECT 
        org.id AS org_id,
        org.name AS org_name,
        org.type AS org_type,
        c.id AS comment_id,
        c.length AS comment_length
    FROM person_work_at_company pwc
    JOIN organisation org 
        ON pwc.company_id = org.id
    JOIN person p 
        ON pwc.person_id = p.id
    JOIN comment c 
        ON c.creator_person_id = p.id
),
comment_likes AS (
    SELECT 
        comment_id,
        COUNT(*) AS like_count
    FROM person_likes_comment
    GROUP BY comment_id
)
SELECT 
    ec.org_id,
    ec.org_name,
    ec.org_type,
    COUNT(DISTINCT ec.comment_id) AS comment_count,
    COALESCE(SUM(cl.like_count), 0) AS total_likes,
    AVG(ec.comment_length) AS avg_comment_length
FROM employee_comments ec
LEFT JOIN comment_likes cl 
    ON cl.comment_id = ec.comment_id
GROUP BY 
    ec.org_id,
    ec.org_name,
    ec.org_type
ORDER BY total_likes DESC
LIMIT 10
