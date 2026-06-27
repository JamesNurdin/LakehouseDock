WITH comment_tag AS (
    SELECT
        c.id AS comment_id,
        c.length AS comment_length,
        c.creator_person_id,
        c.location_country_id,
        cht.tag_id
    FROM comment c
    JOIN comment_has_tag_tag cht
        ON cht.comment_id = c.id
),
tag_info AS (
    SELECT
        t.id AS tag_id,
        t.name AS tag_name
    FROM tag t
),
person_info AS (
    SELECT
        p.id AS person_id,
        p.gender
    FROM person p
),
country_place AS (
    SELECT
        pl.id AS country_id,
        pl.part_of_place_id AS continent_id
    FROM place pl
),
continent_place AS (
    SELECT
        pl.id AS continent_id,
        pl.name AS continent_name
    FROM place pl
)
SELECT
    t.tag_name,
    AVG(ct.comment_length) AS avg_comment_length,
    COUNT(*) AS comment_count
FROM comment_tag ct
JOIN tag_info t
    ON t.tag_id = ct.tag_id
JOIN person_info p
    ON p.person_id = ct.creator_person_id
JOIN country_place cp
    ON cp.country_id = ct.location_country_id
JOIN continent_place co
    ON co.continent_id = cp.continent_id
WHERE p.gender = 'male'
  AND co.continent_name = 'Europe'
GROUP BY t.tag_name
ORDER BY avg_comment_length DESC
LIMIT 10
