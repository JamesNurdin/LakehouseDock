WITH org_employees AS (
    SELECT
        pwac.company_id AS org_id,
        pwac.person_id
    FROM person_work_at_company pwac
),
org_comments AS (
    SELECT
        pwac.company_id AS org_id,
        c.id AS comment_id,
        c.length
    FROM comment c
    JOIN person p
        ON c.creator_person_id = p.id
    JOIN person_work_at_company pwac
        ON pwac.person_id = p.id
),
org_likes AS (
    SELECT
        pwac.company_id AS org_id,
        plc.comment_id
    FROM person_likes_comment plc
    JOIN comment c
        ON plc.comment_id = c.id
    JOIN person p
        ON c.creator_person_id = p.id
    JOIN person_work_at_company pwac
        ON pwac.person_id = p.id
),
org_tags AS (
    SELECT
        pwac.company_id AS org_id,
        cht.tag_id
    FROM comment_has_tag_tag cht
    JOIN comment c
        ON cht.comment_id = c.id
    JOIN person p
        ON c.creator_person_id = p.id
    JOIN person_work_at_company pwac
        ON pwac.person_id = p.id
)
SELECT
    o.id,
    o.name,
    o.type,
    COALESCE(emp.employee_count, 0) AS employee_count,
    COALESCE(comm.comment_count, 0) AS comment_count,
    comm.avg_comment_length,
    COALESCE(likes.total_likes, 0) AS total_likes,
    COALESCE(tags.distinct_tag_count, 0) AS distinct_tag_count
FROM organisation o
LEFT JOIN (
    SELECT
        org_id,
        COUNT(DISTINCT person_id) AS employee_count
    FROM org_employees
    GROUP BY org_id
) emp
    ON emp.org_id = o.id
LEFT JOIN (
    SELECT
        org_id,
        COUNT(DISTINCT comment_id) AS comment_count,
        AVG(length) AS avg_comment_length
    FROM org_comments
    GROUP BY org_id
) comm
    ON comm.org_id = o.id
LEFT JOIN (
    SELECT
        org_id,
        COUNT(*) AS total_likes
    FROM org_likes
    GROUP BY org_id
) likes
    ON likes.org_id = o.id
LEFT JOIN (
    SELECT
        org_id,
        COUNT(DISTINCT tag_id) AS distinct_tag_count
    FROM org_tags
    GROUP BY org_id
) tags
    ON tags.org_id = o.id
WHERE o.type = 'Company'
ORDER BY employee_count DESC
LIMIT 100
