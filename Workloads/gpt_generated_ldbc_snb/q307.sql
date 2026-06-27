/*
  Analytical query: number of comments, average length and distinct commenters
  broken down by country, city and gender.
  Joins follow the allowed rules and only the selected tables/columns are used.
*/
WITH comment_stats AS (
    SELECT
        c.id AS comment_id,
        c.length AS comment_length,
        c.creator_person_id,
        c.location_country_id
    FROM comment AS c
    WHERE c.length > 0
)
SELECT
    pc_country.name AS country_name,
    pc_city.name    AS city_name,
    per.gender      AS gender,
    COUNT(cs.comment_id)                AS comment_count,
    AVG(cs.comment_length)              AS avg_comment_length,
    COUNT(DISTINCT per.id)              AS unique_commenters
FROM comment_stats AS cs
JOIN person AS per
    ON cs.creator_person_id = per.id
JOIN place  AS pc_country
    ON cs.location_country_id = pc_country.id
JOIN place  AS pc_city
    ON per.location_city_id = pc_city.id
GROUP BY pc_country.name, pc_city.name, per.gender
ORDER BY comment_count DESC
LIMIT 20
