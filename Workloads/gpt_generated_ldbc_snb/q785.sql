WITH person_post AS (
    SELECT
        p.id AS person_id,
        p.first_name,
        p.last_name,
        p.gender,
        p.location_city_id,
        po.id AS post_id,
        po.creation_date AS post_creation_date,
        po.length,
        po.language AS post_language,
        po.browser_used AS post_browser_used
    FROM person p
    LEFT JOIN post po
        ON po.creator_person_id = p.id
)
SELECT
    person_id,
    first_name,
    last_name,
    gender,
    location_city_id,
    COUNT(post_id) AS post_count,
    SUM(length) AS total_length,
    AVG(length) AS avg_length,
    MIN(post_creation_date) AS earliest_post_date,
    MAX(post_creation_date) AS latest_post_date,
    COUNT(DISTINCT post_language) AS distinct_post_languages,
    COUNT(DISTINCT post_browser_used) AS distinct_post_browsers
FROM person_post
GROUP BY
    person_id,
    first_name,
    last_name,
    gender,
    location_city_id
ORDER BY post_count DESC
LIMIT 100
