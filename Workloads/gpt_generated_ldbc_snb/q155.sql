-- Count of female persons interested in each tag and their comment‑like activity
WITH person_interest AS (
    SELECT
        p.id AS person_id,
        p.gender,
        p.location_city_id,
        t.id AS tag_id,
        t.name AS tag_name,
        t.type_tag_class_id
    FROM person p
    JOIN person_has_interest_tag pit ON pit.person_id = p.id
    JOIN tag t ON pit.tag_id = t.id
),
person_comment_likes AS (
    SELECT
        pl.person_id,
        COUNT(*) AS comment_likes
    FROM person_likes_comment pl
    GROUP BY pl.person_id
)
SELECT
    i.tag_id,
    i.tag_name,
    i.type_tag_class_id,
    COUNT(DISTINCT i.person_id) AS interested_female_persons,
    SUM(COALESCE(l.comment_likes, 0)) AS total_comment_likes,
    AVG(COALESCE(l.comment_likes, 0)) AS avg_comment_likes_per_person
FROM person_interest i
LEFT JOIN person_comment_likes l ON i.person_id = l.person_id
WHERE i.gender = 'female'
GROUP BY i.tag_id, i.tag_name, i.type_tag_class_id
ORDER BY total_comment_likes DESC
LIMIT 20
