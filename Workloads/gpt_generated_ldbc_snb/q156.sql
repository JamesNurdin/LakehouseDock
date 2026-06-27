-- Analytical query: total likes per gender and city
WITH likes_per_person AS (
    SELECT
        p.id AS person_id,
        p.gender,
        p.location_city_id,
        COUNT(plc.comment_id) AS likes_cnt
    FROM person p
    JOIN person_likes_comment plc
        ON plc.person_id = p.id
    GROUP BY p.id, p.gender, p.location_city_id
)
SELECT
    gender,
    location_city_id,
    COUNT(person_id) AS person_count,
    SUM(likes_cnt) AS total_likes,
    AVG(likes_cnt) AS avg_likes_per_person
FROM likes_per_person
GROUP BY gender, location_city_id
ORDER BY total_likes DESC
LIMIT 20
