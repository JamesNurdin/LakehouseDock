WITH tag_counts AS (
    SELECT
        person_id,
        COUNT(*) AS num_tags
    FROM person_has_interest_tag
    GROUP BY person_id
), city_stats AS (
    SELECT
        p.location_city_id AS city_id,
        pl.name AS city_name,
        COUNT(DISTINCT p.id) AS total_residents,
        COUNT(DISTINCT CASE WHEN pwac.company_id IS NOT NULL AND pl_work.id = p.location_city_id THEN p.id END) AS residents_working_in_city,
        COUNT(DISTINCT CASE WHEN psu.university_id IS NOT NULL AND pl_uni.id = p.location_city_id THEN p.id END) AS residents_studying_in_city,
        AVG(tag_counts.num_tags) AS avg_tags_per_person,
        COUNT(DISTINCT pl_like.person_id) AS persons_who_liked_posts
    FROM person p
    LEFT JOIN place pl ON p.location_city_id = pl.id
    LEFT JOIN person_work_at_company pwac ON pwac.person_id = p.id
    LEFT JOIN organisation org_work ON pwac.company_id = org_work.id
    LEFT JOIN place pl_work ON org_work.location_place_id = pl_work.id
    LEFT JOIN person_study_at_university psu ON psu.person_id = p.id
    LEFT JOIN organisation org_uni ON psu.university_id = org_uni.id
    LEFT JOIN place pl_uni ON org_uni.location_place_id = pl_uni.id
    LEFT JOIN tag_counts ON tag_counts.person_id = p.id
    LEFT JOIN person_likes_post pl_like ON pl_like.person_id = p.id
    GROUP BY p.location_city_id, pl.name
)
SELECT
    city_name,
    total_residents,
    residents_working_in_city,
    residents_studying_in_city,
    avg_tags_per_person,
    persons_who_liked_posts
FROM city_stats
ORDER BY total_residents DESC
LIMIT 20
