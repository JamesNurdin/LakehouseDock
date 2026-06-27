/*
   Analytical query: Top 10 forums ordered by the total number of likes given by their moderator.
   For each forum we also return the moderator's name, city, count of distinct interest tags,
   number of companies the moderator has worked for, number of universities attended, and the
   total likes the moderator has made.
*/
WITH moderator_stats AS (
    SELECT
        p.id AS person_id,
        p.first_name,
        p.last_name,
        pl.name AS city_name,
        COUNT(DISTINCT pit.tag_id) AS interest_tag_count,
        COUNT(DISTINCT pwc.company_id) AS company_count,
        COUNT(DISTINCT psu.university_id) AS university_count,
        COUNT(plp.post_id) AS likes_given_count
    FROM person p
    LEFT JOIN place pl ON p.location_city_id = pl.id
    LEFT JOIN person_has_interest_tag pit ON pit.person_id = p.id
    LEFT JOIN person_work_at_company pwc ON pwc.person_id = p.id
    LEFT JOIN person_study_at_university psu ON psu.person_id = p.id
    LEFT JOIN person_likes_post plp ON plp.person_id = p.id
    GROUP BY p.id, p.first_name, p.last_name, pl.name
)
SELECT
    f.id AS forum_id,
    f.title AS forum_title,
    f.creation_date AS forum_creation_date,
    ms.first_name AS moderator_first_name,
    ms.last_name AS moderator_last_name,
    ms.city_name AS moderator_city,
    ms.interest_tag_count,
    ms.company_count,
    ms.university_count,
    ms.likes_given_count
FROM forum f
JOIN moderator_stats ms ON f.moderator_person_id = ms.person_id
ORDER BY ms.likes_given_count DESC
LIMIT 10
