WITH employee_posts AS (
    SELECT
        o.id AS org_id,
        o.name AS org_name,
        p.id AS person_id,
        COUNT(post.id) AS post_count,
        AVG(post.length) AS avg_post_length,
        AVG(pwc.work_from) AS avg_work_from
    FROM person p
    JOIN person_work_at_company pwc
        ON pwc.person_id = p.id
    JOIN organisation o
        ON pwc.company_id = o.id
    LEFT JOIN post
        ON post.creator_person_id = p.id
    GROUP BY o.id, o.name, p.id
),
employee_forum_members AS (
    SELECT
        o.id AS org_id,
        COUNT(DISTINCT fhm.person_id) AS forum_member_count
    FROM organisation o
    JOIN person_work_at_company pwc
        ON pwc.company_id = o.id
    JOIN forum_has_member_person fhm
        ON fhm.person_id = pwc.person_id
    GROUP BY o.id
),
employee_connections AS (
    SELECT
        o.id AS org_id,
        COUNT(*) AS connection_count
    FROM person_knows_person pkn
    JOIN person p1
        ON pkn.person1_id = p1.id
    JOIN person_work_at_company pwc1
        ON pwc1.person_id = p1.id
    JOIN organisation o
        ON pwc1.company_id = o.id
    JOIN person p2
        ON pkn.person2_id = p2.id
    JOIN person_work_at_company pwc2
        ON pwc2.person_id = p2.id
    WHERE pwc2.company_id = o.id
    GROUP BY o.id
)
SELECT
    ep.org_id,
    ep.org_name,
    SUM(ep.post_count) AS total_posts,
    AVG(ep.avg_post_length) AS avg_post_length_across_employees,
    AVG(ep.avg_work_from) AS avg_work_start_year,
    fm.forum_member_count,
    ec.connection_count,
    COUNT(DISTINCT ep.person_id) AS employee_count
FROM employee_posts ep
JOIN employee_forum_members fm
    ON fm.org_id = ep.org_id
LEFT JOIN employee_connections ec
    ON ec.org_id = ep.org_id
GROUP BY ep.org_id, ep.org_name, fm.forum_member_count, ec.connection_count
ORDER BY total_posts DESC
LIMIT 10
