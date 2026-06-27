WITH person_like_counts AS (
    SELECT
        p.id,
        p.first_name,
        p.last_name,
        p.gender,
        p.location_city_id,
        COUNT(plp.post_id) AS likes_given
    FROM person p
    LEFT JOIN person_likes_post plp
        ON plp.person_id = p.id
    GROUP BY p.id, p.first_name, p.last_name, p.gender, p.location_city_id
),
ranked_persons AS (
    SELECT
        id,
        first_name,
        last_name,
        gender,
        location_city_id,
        likes_given,
        ROW_NUMBER() OVER (PARTITION BY gender ORDER BY likes_given DESC) AS gender_rank
    FROM person_like_counts
)
SELECT
    id,
    first_name,
    last_name,
    gender,
    location_city_id,
    likes_given
FROM ranked_persons
WHERE gender_rank <= 5
ORDER BY gender, likes_given DESC
