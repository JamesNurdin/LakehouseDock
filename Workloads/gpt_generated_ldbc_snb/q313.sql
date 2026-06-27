WITH comment_person_country AS (
    SELECT
        c.id AS comment_id,
        c.length AS comment_length,
        p.id AS person_id,
        p.gender AS gender,
        pc.id AS comment_country_id,
        pc.name AS comment_country_name,
        city.id AS city_id,
        city.name AS city_name,
        pcountry.id AS person_country_id,
        pcountry.name AS person_country_name
    FROM comment c
    JOIN person p ON c.creator_person_id = p.id
    JOIN place pc ON c.location_country_id = pc.id
    JOIN place city ON p.location_city_id = city.id
    JOIN place pcountry ON city.part_of_place_id = pcountry.id
    WHERE c.length > 0
)
SELECT
    person_country_name,
    comment_country_name,
    gender,
    COUNT(*) AS comment_count,
    AVG(comment_length) AS avg_comment_length,
    COUNT(DISTINCT person_id) AS distinct_commenters
FROM comment_person_country
GROUP BY person_country_name, comment_country_name, gender
ORDER BY comment_count DESC
LIMIT 20
