WITH
    posts_by_place AS (
        SELECT p.location_country_id AS place_id,
               count(*) AS post_count
        FROM post p
        GROUP BY p.location_country_id
    ),
    comments_by_place AS (
        SELECT c.location_country_id AS place_id,
               count(*) AS comment_count
        FROM comment c
        GROUP BY c.location_country_id
    ),
    orgs_by_place AS (
        SELECT o.location_place_id AS place_id,
               count(*) AS org_count,
               sum(CASE WHEN o.type = 'Company' THEN 1 ELSE 0 END) AS company_count,
               sum(CASE WHEN o.type = 'University' THEN 1 ELSE 0 END) AS university_count
        FROM organisation o
        GROUP BY o.location_place_id
    ),
    workers_by_place AS (
        SELECT o.location_place_id AS place_id,
               count(DISTINCT pwc.person_id) AS worker_count
        FROM person_work_at_company pwc
        JOIN organisation o
          ON pwc.company_id = o.id
        GROUP BY o.location_place_id
    ),
    students_by_place AS (
        SELECT o.location_place_id AS place_id,
               count(DISTINCT psu.person_id) AS student_count
        FROM person_study_at_university psu
        JOIN organisation o
          ON psu.university_id = o.id
        GROUP BY o.location_place_id
    )
SELECT pl.id AS place_id,
       pl.name AS place_name,
       coalesce(pbp.post_count, 0)      AS post_count,
       coalesce(cb.comment_count, 0)    AS comment_count,
       coalesce(ob.org_count, 0)        AS org_count,
       coalesce(ob.company_count, 0)    AS company_count,
       coalesce(ob.university_count, 0) AS university_count,
       coalesce(wb.worker_count, 0)    AS worker_count,
       coalesce(sb.student_count, 0)   AS student_count,
       (coalesce(pbp.post_count, 0) + coalesce(cb.comment_count, 0)) AS total_activity
FROM place pl
LEFT JOIN posts_by_place pbp   ON pl.id = pbp.place_id   -- post.location_country_id = place.id
LEFT JOIN comments_by_place cb ON pl.id = cb.place_id   -- comment.location_country_id = place.id
LEFT JOIN orgs_by_place ob     ON pl.id = ob.place_id   -- organisation.location_place_id = place.id
LEFT JOIN workers_by_place wb  ON pl.id = wb.place_id   -- via organisation
LEFT JOIN students_by_place sb ON pl.id = sb.place_id   -- via organisation
ORDER BY total_activity DESC
LIMIT 10
