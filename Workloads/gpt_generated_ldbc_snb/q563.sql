WITH org_counts AS (
    SELECT
        cont.id   AS continent_id,
        cont.name AS continent_name,
        COUNT(DISTINCT org.id) AS org_cnt
    FROM organisation org
    JOIN place city      ON org.location_place_id = city.id
    JOIN place country   ON city.part_of_place_id = country.id
    JOIN place cont      ON country.part_of_place_id = cont.id
    GROUP BY cont.id, cont.name
)
SELECT
    cont.name                                 AS continent_name,
    COUNT(c.id)                               AS total_comments,
    SUM(c.length)                             AS total_comment_length,
    AVG(c.length)                             AS avg_comment_length,
    COUNT(DISTINCT c.creator_person_id)       AS distinct_commenters,
    COUNT(DISTINCT CASE WHEN p.gender = 'male'   THEN p.id END) AS male_commenters,
    COUNT(DISTINCT CASE WHEN p.gender = 'female' THEN p.id END) AS female_commenters,
    COALESCE(org_cnt.org_cnt, 0)              AS organisations_in_continent
FROM comment c
JOIN person p        ON c.creator_person_id = p.id
JOIN place country   ON c.location_country_id = country.id
JOIN place cont      ON country.part_of_place_id = cont.id
LEFT JOIN org_counts org_cnt ON cont.id = org_cnt.continent_id
GROUP BY cont.id, cont.name, org_cnt.org_cnt
ORDER BY total_comments DESC
