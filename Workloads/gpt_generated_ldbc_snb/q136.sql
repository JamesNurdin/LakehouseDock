WITH likes_per_person AS (
    SELECT
        plp.person_id,
        p.first_name,
        p.last_name,
        p.gender,
        COUNT(*) AS like_count,
        MIN(plp.creation_date) AS first_like_date,
        MAX(plp.creation_date) AS last_like_date
    FROM person_likes_post plp
    JOIN person p
        ON plp.person_id = p.id
    GROUP BY plp.person_id, p.first_name, p.last_name, p.gender
)
SELECT
    gender,
    COUNT(*) AS person_count,
    SUM(like_count) AS total_likes,
    AVG(like_count) AS avg_likes_per_person,
    MIN(first_like_date) AS earliest_like_date,
    MAX(last_like_date) AS latest_like_date
FROM likes_per_person
GROUP BY gender
ORDER BY gender
