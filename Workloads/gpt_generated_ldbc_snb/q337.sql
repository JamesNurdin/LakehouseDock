WITH org_emp AS (
    SELECT
        o.id AS org_id,
        o.type AS org_type,
        pwc.person_id AS person_id
    FROM organisation o
    LEFT JOIN person_work_at_company pwc
        ON pwc.company_id = o.id
),
emp_posts AS (
    SELECT
        p.creator_person_id AS person_id,
        COUNT(p.id) AS post_count,
        SUM(p.length) AS total_post_length
    FROM post p
    GROUP BY p.creator_person_id
),
emp_likes AS (
    SELECT
        plc.person_id,
        COUNT(plc.person_id) AS likes_count
    FROM person_likes_comment plc
    GROUP BY plc.person_id
),
org_employee_agg AS (
    SELECT
        org_emp.org_id,
        org_emp.org_type,
        COUNT(DISTINCT org_emp.person_id) AS employee_count,
        COALESCE(SUM(ep.post_count), 0) AS total_posts_by_employees,
        COALESCE(SUM(ep.total_post_length), 0) AS total_post_length_by_employees,
        COALESCE(SUM(el.likes_count), 0) AS total_likes_by_employees
    FROM org_emp
    LEFT JOIN emp_posts ep
        ON ep.person_id = org_emp.person_id
    LEFT JOIN emp_likes el
        ON el.person_id = org_emp.person_id
    GROUP BY org_emp.org_id, org_emp.org_type
),
org_comments_liked AS (
    SELECT
        o.id AS org_id,
        COUNT(DISTINCT plc.comment_id) AS distinct_comments_liked
    FROM organisation o
    LEFT JOIN person_work_at_company pwc
        ON pwc.company_id = o.id
    LEFT JOIN person_likes_comment plc
        ON plc.person_id = pwc.person_id
    GROUP BY o.id
)
SELECT
    oa.org_id,
    oa.org_type,
    oa.employee_count,
    oa.total_posts_by_employees,
    oa.total_post_length_by_employees,
    oa.total_post_length_by_employees / NULLIF(oa.total_posts_by_employees, 0) AS avg_post_length_by_employees,
    oa.total_likes_by_employees,
    COALESCE(ocl.distinct_comments_liked, 0) AS distinct_comments_liked_by_employees
FROM org_employee_agg oa
LEFT JOIN org_comments_liked ocl
    ON ocl.org_id = oa.org_id
ORDER BY oa.employee_count DESC, oa.org_id
