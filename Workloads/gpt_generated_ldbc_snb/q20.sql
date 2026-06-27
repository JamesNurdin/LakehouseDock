WITH liker_location AS (
    SELECT
        p.id AS liker_id,
        p.gender,
        pc.id AS liker_city_id,
        pc_part.id AS liker_country_id,
        pc_part.name AS liker_country_name
    FROM person p
    JOIN place pc ON p.location_city_id = pc.id
    JOIN place pc_part ON pc.part_of_place_id = pc_part.id
),
post_info AS (
    SELECT
        po.id AS post_id,
        po.length,
        po.language,
        pc.id AS post_country_id,
        pc.name AS post_country_name
    FROM post po
    JOIN place pc ON po.location_country_id = pc.id
)
SELECT
    pi.post_country_id AS country_id,
    pi.post_country_name AS country_name,
    ll.gender,
    CASE WHEN ll.liker_country_id = pi.post_country_id THEN 'local' ELSE 'external' END AS like_origin,
    COUNT(*) AS total_likes,
    AVG(pi.length) AS avg_post_length,
    COUNT(DISTINCT pi.post_id) AS distinct_posts_liked
FROM person_likes_post plp
JOIN liker_location ll ON plp.person_id = ll.liker_id
JOIN post_info pi ON plp.post_id = pi.post_id
WHERE pi.language = 'en'
GROUP BY
    pi.post_country_id,
    pi.post_country_name,
    ll.gender,
    CASE WHEN ll.liker_country_id = pi.post_country_id THEN 'local' ELSE 'external' END
ORDER BY total_likes DESC
LIMIT 100
