WITH city_posts AS (
    SELECT
        p.id AS person_id,
        p.gender,
        pl_city.id AS city_id,
        pl_city.name AS city_name,
        pl_region.id AS region_id,
        pl_region.name AS region_name,
        post.id AS post_id,
        post.length AS post_length,
        post.language AS post_language,
        post.creation_date AS post_creation_date,
        post.location_country_id AS country_id
    FROM post
    JOIN person p
        ON post.creator_person_id = p.id
    JOIN place pl_city
        ON p.location_city_id = pl_city.id
    LEFT JOIN place pl_region
        ON pl_city.part_of_place_id = pl_region.id
    JOIN place pl_country
        ON post.location_country_id = pl_country.id
)
SELECT
    city_id,
    city_name,
    region_name,
    COUNT(DISTINCT post_id) AS total_posts,
    AVG(post_length) AS avg_post_length,
    COUNT(DISTINCT person_id) AS unique_creators,
    SUM(CASE WHEN gender = 'male' THEN 1 ELSE 0 END) AS male_creators,
    SUM(CASE WHEN gender = 'female' THEN 1 ELSE 0 END) AS female_creators,
    SUM(CASE WHEN gender NOT IN ('male', 'female') THEN 1 ELSE 0 END) AS other_gender_creators
FROM city_posts
GROUP BY city_id, city_name, region_name
ORDER BY total_posts DESC
LIMIT 10
