WITH alumni_posts AS (
    SELECT
        p.id AS post_id,
        p.length AS post_length,
        per.id AS person_id,
        uni.id AS university_id,
        uni.name AS university_name,
        uni.location_place_id AS university_place_id,
        comp.id AS company_id,
        comp.name AS company_name,
        comp.location_place_id AS company_place_id
    FROM post p
    JOIN person per ON p.creator_person_id = per.id
    JOIN person_study_at_university stu ON stu.person_id = per.id
    JOIN organisation uni ON stu.university_id = uni.id
    JOIN person_work_at_company wc ON wc.person_id = per.id
    JOIN organisation comp ON wc.company_id = comp.id
    WHERE lower(uni.type) = 'university'
      AND lower(comp.type) = 'company'
      AND uni.location_place_id <> comp.location_place_id
      AND p.length IS NOT NULL
),
uni_agg AS (
    SELECT
        university_id,
        university_name,
        COUNT(DISTINCT post_id) AS post_count,
        COUNT(DISTINCT person_id) AS alumni_count,
        SUM(post_length) AS total_length,
        AVG(post_length) AS avg_length
    FROM alumni_posts
    GROUP BY university_id, university_name
)
SELECT
    university_id,
    university_name,
    post_count,
    alumni_count,
    total_length,
    avg_length,
    RANK() OVER (ORDER BY post_count DESC) AS university_rank
FROM uni_agg
ORDER BY university_rank
LIMIT 10
