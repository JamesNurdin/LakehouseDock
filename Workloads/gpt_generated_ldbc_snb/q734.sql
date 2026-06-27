/*
   Analytical query: comment activity of persons who studied at a university and work at a company.
   For each (university, company) pair we count distinct students, total comments, average comment length,
   and the number of distinct countries where those comments were posted.
*/
WITH student_employee_comments AS (
    SELECT
        p.id AS person_id,
        psu.university_id,
        pwac.company_id,
        c.id AS comment_id,
        c.length AS comment_length,
        c.location_country_id AS comment_country_id
    FROM person p
    JOIN comment c
        ON c.creator_person_id = p.id
    JOIN person_study_at_university psu
        ON psu.person_id = p.id
    JOIN person_work_at_company pwac
        ON pwac.person_id = p.id
)
SELECT
    uni.id AS university_id,
    uni.name AS university_name,
    comp.id AS company_id,
    comp.name AS company_name,
    COUNT(DISTINCT sec.person_id) AS num_persons,
    COUNT(sec.comment_id) AS total_comments,
    AVG(sec.comment_length) AS avg_comment_length,
    COUNT(DISTINCT sec.comment_country_id) AS num_countries_commented
FROM student_employee_comments sec
JOIN organisation uni
    ON uni.id = sec.university_id
JOIN organisation comp
    ON comp.id = sec.company_id
WHERE uni.type = 'university'
  AND comp.type = 'company'
GROUP BY uni.id, uni.name, comp.id, comp.name
ORDER BY total_comments DESC
LIMIT 100
