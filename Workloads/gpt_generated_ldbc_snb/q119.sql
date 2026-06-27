WITH employee_counts AS (
    SELECT
        pwac.company_id,
        COUNT(DISTINCT pwac.person_id) AS num_employees
    FROM person_work_at_company pwac
    GROUP BY pwac.company_id
),
post_counts AS (
    SELECT
        pwac.company_id,
        COUNT(DISTINCT p.id) AS num_posts
    FROM person_work_at_company pwac
    JOIN person per
        ON pwac.person_id = per.id
    JOIN post p
        ON p.creator_person_id = per.id
    GROUP BY pwac.company_id
),
comment_stats AS (
    SELECT
        pwac.company_id,
        COUNT(c.id) AS num_comments,
        AVG(c.length) AS avg_comment_length
    FROM person_work_at_company pwac
    JOIN person per
        ON pwac.person_id = per.id
    JOIN comment c
        ON c.creator_person_id = per.id
    GROUP BY pwac.company_id
)
SELECT
    org.id AS company_id,
    org.name AS company_name,
    COALESCE(ec.num_employees, 0) AS num_employees,
    COALESCE(pc.num_posts, 0) AS num_posts,
    COALESCE(cs.num_comments, 0) AS num_comments,
    cs.avg_comment_length
FROM organisation org
LEFT JOIN employee_counts ec
    ON ec.company_id = org.id
LEFT JOIN post_counts pc
    ON pc.company_id = org.id
LEFT JOIN comment_stats cs
    ON cs.company_id = org.id
WHERE org.type = 'Company'
ORDER BY num_comments DESC, num_posts DESC
LIMIT 100
