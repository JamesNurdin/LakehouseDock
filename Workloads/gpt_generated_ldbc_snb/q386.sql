/*
  Analytical query: for each country compute the number of posts, average post length,
  distinct creators of those posts, distinct residents (persons living in the country),
  and distinct organisations located in the country.
  All joins follow the allowed relationships between the base tables.
*/
WITH post_metrics AS (
    SELECT
        p.location_country_id AS country_id,
        COUNT(*) AS post_count,
        AVG(p.length) AS avg_post_length,
        COUNT(DISTINCT p.creator_person_id) AS distinct_creators
    FROM post p
    GROUP BY p.location_country_id
),
person_country AS (
    SELECT
        city.part_of_place_id AS country_id,
        COUNT(DISTINCT per.id) AS distinct_residents
    FROM person per
    JOIN place city ON per.location_city_id = city.id
    GROUP BY city.part_of_place_id
),
org_country AS (
    SELECT
        loc.part_of_place_id AS country_id,
        COUNT(DISTINCT org.id) AS distinct_organisations
    FROM organisation org
    JOIN place loc ON org.location_place_id = loc.id
    GROUP BY loc.part_of_place_id
),
country_names AS (
    SELECT
        pl.id AS country_id,
        pl.name AS country_name
    FROM place pl
    WHERE pl.type = 'Country'
)
SELECT
    cn.country_id,
    cn.country_name,
    COALESCE(pm.post_count, 0)          AS post_count,
    COALESCE(pm.avg_post_length, 0)     AS avg_post_length,
    COALESCE(pm.distinct_creators, 0)  AS distinct_creators,
    COALESCE(pc.distinct_residents, 0) AS distinct_residents,
    COALESCE(oc.distinct_organisations, 0) AS distinct_organisations
FROM country_names cn
LEFT JOIN post_metrics pm   ON cn.country_id = pm.country_id
LEFT JOIN person_country pc ON cn.country_id = pc.country_id
LEFT JOIN org_country oc    ON cn.country_id = oc.country_id
ORDER BY post_count DESC
LIMIT 20
