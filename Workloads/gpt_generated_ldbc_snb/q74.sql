WITH org_info AS (
    SELECT
        o.id AS org_id,
        o.name AS org_name,
        o.url AS org_url,
        pl.name AS city_name,
        pl.type AS city_type,
        parent_pl.name AS region_name
    FROM organisation o
    JOIN place pl ON o.location_place_id = pl.id
    LEFT JOIN place parent_pl ON pl.part_of_place_id = parent_pl.id
),
employee_data AS (
    SELECT
        pwac.company_id,
        pwac.person_id,
        pwac.work_from,
        p.email
    FROM person_work_at_company pwac
    JOIN person p ON pwac.person_id = p.id
),
forum_mod AS (
    SELECT
        pwac.company_id,
        f.id AS forum_id,
        f.title AS forum_title
    FROM forum f
    JOIN person p_mod ON f.moderator_person_id = p_mod.id
    JOIN person_work_at_company pwac ON p_mod.id = pwac.person_id
    JOIN organisation o ON pwac.company_id = o.id
)
SELECT
    o.org_id,
    o.org_name,
    o.org_url,
    o.city_name,
    o.city_type,
    o.region_name,
    COUNT(DISTINCT e.person_id) AS num_employees,
    AVG(e.work_from) AS avg_work_from,
    COUNT(DISTINCT f.forum_id) AS num_moderated_forums,
    COUNT(DISTINCT f.forum_title) AS num_unique_forum_titles,
    COUNT(DISTINCT split_part(e.email, '@', 2)) AS num_unique_email_domains
FROM org_info o
LEFT JOIN employee_data e ON o.org_id = e.company_id
LEFT JOIN forum_mod f ON o.org_id = f.company_id
GROUP BY
    o.org_id,
    o.org_name,
    o.org_url,
    o.city_name,
    o.city_type,
    o.region_name
ORDER BY num_employees DESC
LIMIT 20
