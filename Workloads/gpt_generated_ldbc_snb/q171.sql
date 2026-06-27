WITH comment_person AS (
    SELECT
        c.id AS comment_id,
        c.length AS comment_length,
        c.location_country_id,
        p.id AS person_id,
        p.location_city_id
    FROM comment c
    JOIN person p
        ON c.creator_person_id = p.id
),
city_hierarchy AS (
    SELECT
        city.id AS city_id,
        city.name AS city_name,
        parent.id AS country_id,
        parent.name AS country_name
    FROM place city
    JOIN place parent
        ON city.part_of_place_id = parent.id
),
organisation_in_city AS (
    SELECT
        o.id AS org_id,
        o.name AS org_name,
        o.type AS org_type,
        o.location_place_id AS city_id
    FROM organisation o
)
SELECT
    oc.org_id AS organisation_id,
    oc.org_name AS organisation_name,
    oc.org_type AS organisation_type,
    ch.city_name,
    ch.country_name,
    COUNT(cp.comment_id) AS comment_count,
    SUM(CASE WHEN cp.location_country_id = ch.country_id THEN 1 ELSE 0 END) AS comments_in_resident_country,
    AVG(cp.comment_length) AS avg_comment_length,
    SUM(cp.comment_length) AS total_comment_length
FROM comment_person cp
JOIN city_hierarchy ch
    ON cp.location_city_id = ch.city_id
JOIN organisation_in_city oc
    ON oc.city_id = ch.city_id
GROUP BY
    oc.org_id,
    oc.org_name,
    oc.org_type,
    ch.city_name,
    ch.country_name
ORDER BY comment_count DESC
LIMIT 100
