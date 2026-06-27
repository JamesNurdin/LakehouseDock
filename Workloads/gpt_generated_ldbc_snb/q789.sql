WITH person_likes AS (
    SELECT
        p.id,
        p.first_name,
        p.last_name,
        p.email,
        p.gender,
        p.location_city_id,
        COUNT(plp.post_id) AS likes_count
    FROM person AS p
    JOIN person_likes_post AS plp
        ON plp.person_id = p.id
    GROUP BY
        p.id,
        p.first_name,
        p.last_name,
        p.email,
        p.gender,
        p.location_city_id
)
SELECT
    id,
    first_name,
    last_name,
    email,
    gender,
    location_city_id,
    likes_count,
    ROW_NUMBER() OVER (PARTITION BY location_city_id ORDER BY likes_count DESC) AS rank_within_city
FROM person_likes
WHERE likes_count > 0
ORDER BY likes_count DESC
LIMIT 50
