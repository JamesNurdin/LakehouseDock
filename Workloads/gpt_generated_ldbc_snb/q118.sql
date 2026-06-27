WITH employee_posts AS (
    SELECT
        org.id AS org_id,
        org.name AS org_name,
        org.type AS org_type,
        loc_place.name AS org_location_name,
        post.id AS post_id,
        post.length AS post_length,
        person.id AS person_id
    FROM post
    JOIN person ON post.creator_person_id = person.id
    JOIN person_work_at_company pwc ON pwc.person_id = person.id
    JOIN organisation org ON pwc.company_id = org.id
    JOIN place loc_place ON org.location_place_id = loc_place.id
),
student_posts AS (
    SELECT
        org.id AS org_id,
        org.name AS org_name,
        org.type AS org_type,
        loc_place.name AS org_location_name,
        post.id AS post_id,
        post.length AS post_length,
        person.id AS person_id
    FROM post
    JOIN person ON post.creator_person_id = person.id
    JOIN person_study_at_university psu ON psu.person_id = person.id
    JOIN organisation org ON psu.university_id = org.id
    JOIN place loc_place ON org.location_place_id = loc_place.id
),
combined AS (
    SELECT
        org_id,
        org_name,
        org_type,
        org_location_name,
        'employee' AS relationship_type,
        post_id,
        post_length,
        person_id
    FROM employee_posts
    UNION ALL
    SELECT
        org_id,
        org_name,
        org_type,
        org_location_name,
        'student' AS relationship_type,
        post_id,
        post_length,
        person_id
    FROM student_posts
)
SELECT
    combined.org_id,
    combined.org_name,
    combined.org_type,
    combined.org_location_name,
    combined.relationship_type,
    COUNT(DISTINCT combined.post_id) AS post_count,
    AVG(combined.post_length) AS avg_post_length,
    COUNT(DISTINCT combined.person_id) AS distinct_creator_count
FROM combined
GROUP BY
    combined.org_id,
    combined.org_name,
    combined.org_type,
    combined.org_location_name,
    combined.relationship_type
ORDER BY post_count DESC
LIMIT 20
