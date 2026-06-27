WITH emp AS (
    SELECT
        p.id AS person_id,
        pl.id AS city_id,
        pl.name AS city_name
    FROM person p
    JOIN place pl
        ON p.location_city_id = pl.id
    JOIN person_work_at_company pwc
        ON pwc.person_id = p.id
),
posts_per_emp AS (
    SELECT
        p.creator_person_id AS person_id,
        COUNT(*) AS post_cnt
    FROM post p
    GROUP BY p.creator_person_id
),
likes_per_post AS (
    SELECT
        pl.post_id,
        COUNT(DISTINCT pl.person_id) AS like_cnt
    FROM person_likes_post pl
    GROUP BY pl.post_id
),
likes_per_emp AS (
    SELECT
        p.creator_person_id AS person_id,
        SUM(lp.like_cnt) AS total_likes
    FROM post p
    JOIN likes_per_post lp
        ON p.id = lp.post_id
    GROUP BY p.creator_person_id
),
local_uni_study AS (
    SELECT DISTINCT
        pers.id AS person_id
    FROM person pers
    JOIN person_study_at_university psu
        ON psu.person_id = pers.id
    JOIN organisation uni
        ON uni.id = psu.university_id
    JOIN place city
        ON pers.location_city_id = city.id
    JOIN place uni_loc
        ON uni.location_place_id = uni_loc.id
    WHERE uni_loc.id = city.id
)
SELECT
    e.city_id,
    e.city_name,
    COUNT(DISTINCT e.person_id) AS employee_count,
    AVG(COALESCE(pp.post_cnt, 0)) AS avg_posts_per_employee,
    SUM(COALESCE(lp.total_likes, 0)) AS total_likes_on_employee_posts,
    COUNT(DISTINCT lus.person_id) AS employees_with_local_university_study
FROM emp e
LEFT JOIN posts_per_emp pp
    ON e.person_id = pp.person_id
LEFT JOIN likes_per_emp lp
    ON e.person_id = lp.person_id
LEFT JOIN local_uni_study lus
    ON e.person_id = lus.person_id
GROUP BY e.city_id, e.city_name
ORDER BY employee_count DESC
LIMIT 20
