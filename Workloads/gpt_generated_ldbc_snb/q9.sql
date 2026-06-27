WITH likes_per_person AS (
    SELECT
        pl.person_id,
        COUNT(*) AS likes_count,
        COUNT(DISTINCT pl.comment_id) AS distinct_comments,
        MIN(pl.creation_date) AS first_like_date,
        MAX(pl.creation_date) AS last_like_date
    FROM person_likes_comment pl
    GROUP BY pl.person_id
),
median_likes AS (
    SELECT approx_percentile(likes_count, 0.5) AS median_likes
    FROM likes_per_person
)
SELECT
    p.id,
    p.first_name,
    p.last_name,
    p.gender,
    p.location_city_id,
    l.likes_count,
    l.distinct_comments,
    l.first_like_date,
    l.last_like_date
FROM likes_per_person l
JOIN person p
    ON p.id = l.person_id
CROSS JOIN median_likes m
WHERE l.likes_count > m.median_likes
ORDER BY l.likes_count DESC
LIMIT 50
