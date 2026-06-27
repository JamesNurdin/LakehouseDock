WITH comment_city_country AS (
    SELECT
        c.id AS comment_id,
        c.length,
        c.browser_used,
        c.parent_comment_id,
        p.id AS person_id,
        p.location_city_id AS city_id,
        c.location_country_id AS country_id,
        city_place.name AS city_name,
        city_place.type AS city_type,
        country_place.name AS country_name,
        country_place.type AS country_type,
        region_place.id AS region_id,
        region_place.name AS region_name,
        region_place.type AS region_type
    FROM comment c
    JOIN person p
        ON c.creator_person_id = p.id
    JOIN place city_place
        ON p.location_city_id = city_place.id
    JOIN place country_place
        ON c.location_country_id = country_place.id
    LEFT JOIN place region_place
        ON city_place.part_of_place_id = region_place.id
)
SELECT
    city_id,
    city_name,
    region_name,
    country_name,
    COUNT(*) AS total_comments,
    COUNT(CASE WHEN parent_comment_id IS NULL THEN 1 END) AS top_level_comments,
    COUNT(CASE WHEN parent_comment_id IS NOT NULL THEN 1 END) AS reply_comments,
    AVG(length) AS avg_comment_length,
    (
        SELECT browser_used
        FROM (
            SELECT browser_used, COUNT(*) AS cnt
            FROM comment_city_country cc2
            WHERE cc2.city_id = cc.city_id
            GROUP BY browser_used
            ORDER BY cnt DESC, browser_used
            LIMIT 1
        ) t
    ) AS top_browser
FROM comment_city_country cc
GROUP BY
    city_id,
    city_name,
    region_name,
    country_name
ORDER BY total_comments DESC
LIMIT 20
