/*
  Analytical query: For each company, show its location, the number of posts created by its employees,
  total and average post length, total distinct likes those posts received, and total distinct comments.
  Joins follow the allowed relationships only.
*/
WITH employee_posts AS (
    SELECT
        p_work.company_id,
        p.id AS post_id,
        post.length AS post_length
    FROM person_work_at_company p_work
    JOIN person p ON p_work.person_id = p.id
    JOIN post ON post.creator_person_id = p.id
)
SELECT
    org.id AS company_id,
    org.name AS company_name,
    plc.name AS company_location,
    COUNT(DISTINCT ep.post_id) AS total_posts,
    SUM(ep.post_length) AS total_post_length,
    AVG(ep.post_length) AS avg_post_length,
    COUNT(DISTINCT pl.person_id) AS total_likes_by_any_user,
    COUNT(DISTINCT c.id) AS total_comments_on_posts
FROM employee_posts ep
JOIN organisation org ON ep.company_id = org.id
LEFT JOIN place plc ON org.location_place_id = plc.id
LEFT JOIN person_likes_post pl ON pl.post_id = ep.post_id
LEFT JOIN comment c ON c.parent_post_id = ep.post_id
GROUP BY org.id, org.name, plc.name
ORDER BY total_posts DESC
LIMIT 100
