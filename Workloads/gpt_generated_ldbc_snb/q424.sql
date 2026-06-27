WITH city_country AS (
    -- Resolve each place (city) to its containing country (or itself if no parent)
    SELECT
        city.id AS city_id,
        COALESCE(parent.id, city.id) AS country_id,
        COALESCE(parent.name, city.name) AS country_name
    FROM place city
    LEFT JOIN place parent
        ON city.part_of_place_id = parent.id
),
person_by_country AS (
    SELECT
        cc.country_id,
        COUNT(DISTINCT p.id) AS person_count
    FROM person p
    JOIN city_country cc
        ON p.location_city_id = cc.city_id
    GROUP BY cc.country_id
),
post_by_country AS (
    SELECT
        cc.country_id,
        COUNT(DISTINCT po.id) AS post_count,
        AVG(po.length) AS avg_post_length
    FROM post po
    JOIN person p
        ON po.creator_person_id = p.id
    JOIN city_country cc
        ON p.location_city_id = cc.city_id
    GROUP BY cc.country_id
),
comment_by_country AS (
    SELECT
        cc.country_id,
        COUNT(DISTINCT c.id) AS comment_count,
        AVG(c.length) AS avg_comment_length
    FROM comment c
    JOIN person p
        ON c.creator_person_id = p.id
    JOIN city_country cc
        ON p.location_city_id = cc.city_id
    GROUP BY cc.country_id
),
organisation_by_country AS (
    SELECT
        cc.country_id,
        COUNT(DISTINCT o.id) AS organisation_count
    FROM organisation o
    JOIN city_country cc
        ON o.location_place_id = cc.city_id
    GROUP BY cc.country_id
)
SELECT
    cc.country_id,
    cc.country_name,
    COALESCE(pbc.person_count, 0)          AS person_count,
    COALESCE(pbc2.post_count, 0)           AS post_count,
    COALESCE(pbc2.avg_post_length, 0)      AS avg_post_length,
    COALESCE(cbc.comment_count, 0)         AS comment_count,
    COALESCE(cbc.avg_comment_length, 0)    AS avg_comment_length,
    COALESCE(obc.organisation_count, 0)   AS organisation_count
FROM city_country cc
LEFT JOIN person_by_country pbc
    ON cc.country_id = pbc.country_id
LEFT JOIN post_by_country pbc2
    ON cc.country_id = pbc2.country_id
LEFT JOIN comment_by_country cbc
    ON cc.country_id = cbc.country_id
LEFT JOIN organisation_by_country obc
    ON cc.country_id = obc.country_id
WHERE cc.country_name IS NOT NULL
ORDER BY person_count DESC, country_name
