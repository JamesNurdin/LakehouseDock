WITH likes_per_person AS (
    SELECT
        person_id,
        COUNT(*) AS likes_count,
        MIN(creation_date) AS first_like_date,
        MAX(creation_date) AS last_like_date
    FROM person_likes_comment
    GROUP BY person_id
)
SELECT
    p.gender,
    p.location_city_id,
    COUNT(DISTINCT p.id) AS person_cnt,
    SUM(l.likes_count) AS total_likes,
    AVG(l.likes_count) AS avg_likes_per_person,
    MIN(l.first_like_date) AS earliest_like_date,
    MAX(l.last_like_date) AS latest_like_date
FROM person p
JOIN likes_per_person l
    ON l.person_id = p.id
GROUP BY p.gender, p.location_city_id
ORDER BY total_likes DESC
LIMIT 100
