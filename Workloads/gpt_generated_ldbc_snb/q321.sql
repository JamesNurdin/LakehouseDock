/*
   Analytical query: forum membership summary by region.
   This query aggregates forum membership data, showing the total number of members,
   gender breakdown, geographic spread, interest diversity, and average number of
   interest tags per member for each forum‑region combination.
   All joins respect the allowed join rules and only columns from the selected
   tables are used.
*/
SELECT
    fhm.forum_id,
    region.id   AS region_id,
    region.name AS region_name,
    COUNT(DISTINCT fhm.person_id)                                 AS total_members,
    COUNT(DISTINCT p.id)      FILTER (WHERE p.gender = 'male')   AS male_members,
    COUNT(DISTINCT p.id)      FILTER (WHERE p.gender = 'female') AS female_members,
    COUNT(DISTINCT city.id)                                    AS distinct_cities,
    COUNT(DISTINCT pht.tag_id)                                 AS distinct_interest_tags,
    CAST(COUNT(pht.tag_id) AS DOUBLE) / NULLIF(COUNT(DISTINCT fhm.person_id), 0) AS avg_tags_per_member
FROM forum_has_member_person AS fhm
JOIN person AS p
    ON fhm.person_id = p.id
LEFT JOIN person_has_interest_tag AS pht
    ON p.id = pht.person_id
LEFT JOIN place AS city
    ON p.location_city_id = city.id
LEFT JOIN place AS region
    ON city.part_of_place_id = region.id
GROUP BY
    fhm.forum_id,
    region.id,
    region.name
ORDER BY total_members DESC
LIMIT 20
