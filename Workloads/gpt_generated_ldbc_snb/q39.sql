WITH employees AS (
    SELECT
        pwc.person_id,
        org.id   AS company_id,
        org.name AS company_name
    FROM person_work_at_company pwc
    JOIN organisation org ON pwc.company_id = org.id
    WHERE org.type = 'Company'
),
employee_posts AS (
    SELECT
        e.company_id,
        e.company_name,
        e.person_id,
        p.id                AS post_id,
        p.length            AS post_length,
        p.container_forum_id AS forum_id
    FROM employees e
    JOIN person per ON e.person_id = per.id
    JOIN post p ON p.creator_person_id = per.id
    WHERE p.creation_date >= '2022-01-01'
),
post_likes AS (
    SELECT
        ep.company_id,
        ep.company_name,
        ep.person_id AS employee_id,
        ep.post_id,
        ep.post_length,
        ep.forum_id,
        pl.person_id AS liker_id
    FROM employee_posts ep
    LEFT JOIN person_likes_post pl ON pl.post_id = ep.post_id
    LEFT JOIN person liker ON pl.person_id = liker.id
)
SELECT
    pl.company_id,
    pl.company_name,
    COUNT(DISTINCT pl.employee_id) AS employee_count,
    COUNT(DISTINCT pl.post_id)     AS post_count,
    AVG(pl.post_length)           AS avg_post_length,
    COUNT(DISTINCT pl.liker_id)   AS distinct_likers,
    COUNT(DISTINCT pl.forum_id)   AS forum_count
FROM post_likes pl
GROUP BY pl.company_id, pl.company_name
ORDER BY post_count DESC
LIMIT 10
