WITH person_tag_country AS (
    SELECT
        iht.person_id,
        iht.tag_id,
        p.gender,
        c.id AS city_id,
        co.id AS country_id,
        co.name AS country_name
    FROM person_has_interest_tag iht
    JOIN person p ON iht.person_id = p.id
    JOIN place c ON p.location_city_id = c.id
    JOIN place co ON c.part_of_place_id = co.id
)
SELECT
    ptc.tag_id,
    ptc.country_name,
    ptc.gender,
    COUNT(DISTINCT ptc.person_id) AS distinct_persons,
    COUNT(po.id) AS total_posts,
    AVG(po.length) AS avg_post_length
FROM person_tag_country ptc
LEFT JOIN post po ON po.creator_person_id = ptc.person_id
GROUP BY ptc.tag_id, ptc.country_name, ptc.gender
ORDER BY total_posts DESC
LIMIT 100
