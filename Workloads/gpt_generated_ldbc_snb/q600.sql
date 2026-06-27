WITH comment_cte AS (
    SELECT c.id AS comment_id,
           c.creator_person_id,
           c.parent_post_id
    FROM comment c
),
post_cte AS (
    SELECT p.id AS post_id,
           p.creator_person_id
    FROM post p
),
university_cte AS (
    SELECT o.id AS uni_id,
           o.name AS uni_name
    FROM organisation o
    WHERE o.type = 'University'
),
company_cte AS (
    SELECT o.id AS comp_id,
           o.name AS comp_name
    FROM organisation o
    WHERE o.type = 'Company'
)
SELECT u.uni_name,
       co.comp_name,
       COUNT(*) AS comment_cnt
FROM comment_cte cc
JOIN post_cte pc ON cc.parent_post_id = pc.post_id
JOIN person pcmt ON cc.creator_person_id = pcmt.id
JOIN person pst ON pc.creator_person_id = pst.id
JOIN person_study_at_university stu ON pcmt.id = stu.person_id
JOIN university_cte u ON stu.university_id = u.uni_id
JOIN person_work_at_company wac ON pst.id = wac.person_id
JOIN company_cte co ON wac.company_id = co.comp_id
GROUP BY u.uni_name, co.comp_name
ORDER BY comment_cnt DESC
LIMIT 10
