/* Analytical query: total likes per city, region, and country broken down by liker gender */
WITH likes_detail AS (
    SELECT
        plp.creation_date AS like_creation_date,
        plp.person_id AS liker_id,
        plp.post_id AS liked_post_id,
        p.gender AS liker_gender,
        p.location_city_id AS liker_city_id,
        po.length AS post_length,
        po.creator_person_id AS author_id,
        po.location_country_id AS post_country_id
    FROM person_likes_post plp
    JOIN person p
        ON plp.person_id = p.id
    JOIN post po
        ON plp.post_id = po.id
),
-- Enrich likes with city, region (if any), and country information
enriched AS (
    SELECT
        ld.like_creation_date,
        ld.liker_id,
        ld.liked_post_id,
        ld.liker_gender,
        city.name AS city_name,
        city.type AS city_type,
        region.name AS region_name,
        region.type AS region_type,
        country.name AS country_name,
        country.type AS country_type,
        ld.post_length
    FROM likes_detail ld
    JOIN place city
        ON ld.liker_city_id = city.id
    LEFT JOIN place region
        ON city.part_of_place_id = region.id
    JOIN place country
        ON ld.post_country_id = country.id
)
SELECT
    e.city_name,
    e.city_type,
    e.region_name,
    e.region_type,
    e.country_name,
    e.country_type,
    e.liker_gender,
    COUNT(*) AS total_likes,
    COUNT(DISTINCT e.liked_post_id) AS distinct_posts_liked,
    AVG(e.post_length) AS avg_post_length
FROM enriched e
GROUP BY
    e.city_name,
    e.city_type,
    e.region_name,
    e.region_type,
    e.country_name,
    e.country_type,
    e.liker_gender
ORDER BY total_likes DESC
LIMIT 50
