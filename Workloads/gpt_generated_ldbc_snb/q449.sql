WITH person_tag_likes AS (
    SELECT
        p.id AS person_id,
        p.location_city_id,
        pit.tag_id,
        plp.post_id
    FROM person p
    JOIN person_has_interest_tag pit ON pit.person_id = p.id
    JOIN person_likes_post plp ON plp.person_id = p.id
)
SELECT
    r.name AS region_name,
    pt.tag_id,
    COUNT(pt.post_id) AS total_likes,
    COUNT(DISTINCT pt.person_id) AS distinct_persons
FROM person_tag_likes pt
JOIN place c ON pt.location_city_id = c.id
JOIN place r ON c.part_of_place_id = r.id
GROUP BY r.name, pt.tag_id
ORDER BY total_likes DESC
LIMIT 100
