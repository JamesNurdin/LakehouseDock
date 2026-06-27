WITH employee_posts AS (
    SELECT
        org.id AS org_id,
        org.name AS org_name,
        org.location_place_id AS org_location_place_id,
        pwc.person_id AS employee_id,
        p.id AS post_id,
        p.length AS post_length
    FROM organisation org
    JOIN person_work_at_company pwc
        ON pwc.company_id = org.id
    JOIN person per
        ON per.id = pwc.person_id
    JOIN post p
        ON p.creator_person_id = per.id
)
SELECT
    ep.org_name,
    loc.name AS location_name,
    COUNT(DISTINCT ep.employee_id) AS num_employees_posted,
    COUNT(DISTINCT ep.post_id) AS num_posts,
    SUM(ep.post_length) AS total_post_length,
    AVG(ep.post_length) AS avg_post_length,
    COUNT(DISTINCT plp.person_id) AS num_likes,
    COUNT(DISTINCT c.id) AS num_comments,
    COUNT(DISTINCT pht.tag_id) AS num_distinct_tags
FROM employee_posts ep
LEFT JOIN person_likes_post plp
    ON plp.post_id = ep.post_id
LEFT JOIN comment c
    ON c.parent_post_id = ep.post_id
LEFT JOIN post_has_tag_tag pht
    ON pht.post_id = ep.post_id
JOIN place loc
    ON loc.id = ep.org_location_place_id
GROUP BY ep.org_name, loc.name
ORDER BY num_posts DESC
LIMIT 10
