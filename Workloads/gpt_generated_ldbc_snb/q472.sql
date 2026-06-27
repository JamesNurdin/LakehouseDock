WITH work_latest AS (
    SELECT
        pwc.person_id,
        pc.name AS company_name,
        ROW_NUMBER() OVER (PARTITION BY pwc.person_id ORDER BY pwc.work_from DESC) AS rn
    FROM person_work_at_company pwc
    JOIN organisation pc ON pwc.company_id = pc.id
),
study_latest AS (
    SELECT
        psu.person_id,
        pu.name AS university_name,
        ROW_NUMBER() OVER (PARTITION BY psu.person_id ORDER BY psu.class_year DESC) AS rn
    FROM person_study_at_university psu
    JOIN organisation pu ON psu.university_id = pu.id
),
person_info AS (
    SELECT
        p.id,
        p.first_name,
        p.last_name,
        p.gender,
        p.email,
        city.name AS city_name,
        w.company_name,
        s.university_name
    FROM person p
    LEFT JOIN place city ON p.location_city_id = city.id
    LEFT JOIN work_latest w ON w.person_id = p.id AND w.rn = 1
    LEFT JOIN study_latest s ON s.person_id = p.id AND s.rn = 1
),
comment_agg AS (
    SELECT
        c.creator_person_id AS person_id,
        COUNT(*) AS comment_count,
        AVG(c.length) AS avg_comment_length,
        COUNT(DISTINCT c.location_country_id) AS distinct_comment_countries
    FROM comment c
    GROUP BY c.creator_person_id
)
SELECT
    pi.id AS person_id,
    pi.first_name,
    pi.last_name,
    pi.gender,
    pi.email,
    pi.city_name,
    pi.company_name,
    pi.university_name,
    ca.comment_count,
    ca.avg_comment_length,
    ca.distinct_comment_countries
FROM person_info pi
JOIN comment_agg ca ON ca.person_id = pi.id
ORDER BY ca.comment_count DESC, ca.avg_comment_length DESC
LIMIT 10
