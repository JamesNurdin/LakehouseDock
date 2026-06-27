WITH friend_counts AS (
   SELECT person_id,
          COUNT(DISTINCT friend_id) AS friend_count
   FROM (
        SELECT person1_id AS person_id,
               person2_id AS friend_id
        FROM person_knows_person
        UNION ALL
        SELECT person2_id AS person_id,
               person1_id AS friend_id
        FROM person_knows_person
   ) AS all_friends
   GROUP BY person_id
),
post_likes AS (
   SELECT person_id,
          COUNT(*) AS liked_post_count
   FROM person_likes_post
   GROUP BY person_id
),
comment_likes AS (
   SELECT person_id,
          COUNT(*) AS liked_comment_count
   FROM person_likes_comment
   GROUP BY person_id
),
interest_counts AS (
   SELECT person_id,
          COUNT(*) AS interest_tag_count
   FROM person_has_interest_tag
   GROUP BY person_id
),
study_counts AS (
   SELECT person_id,
          COUNT(DISTINCT university_id) AS study_university_count
   FROM person_study_at_university
   GROUP BY person_id
),
work_counts AS (
   SELECT person_id,
          COUNT(DISTINCT company_id) AS work_company_count
   FROM person_work_at_company
   GROUP BY person_id
),
person_metrics AS (
   SELECT p.id AS person_id,
          p.gender,
          p.location_city_id,
          COALESCE(fc.friend_count, 0) AS friend_count,
          COALESCE(plc.liked_post_count, 0) AS liked_post_count,
          COALESCE(clc.liked_comment_count, 0) AS liked_comment_count,
          COALESCE(ic.interest_tag_count, 0) AS interest_tag_count,
          COALESCE(sc.study_university_count, 0) AS study_university_count,
          COALESCE(wc.work_company_count, 0) AS work_company_count
   FROM person p
   LEFT JOIN friend_counts fc ON fc.person_id = p.id
   LEFT JOIN post_likes plc ON plc.person_id = p.id
   LEFT JOIN comment_likes clc ON clc.person_id = p.id
   LEFT JOIN interest_counts ic ON ic.person_id = p.id
   LEFT JOIN study_counts sc ON sc.person_id = p.id
   LEFT JOIN work_counts wc ON wc.person_id = p.id
)
SELECT pl.name AS city_name,
       COUNT(DISTINCT pm.person_id) AS person_count,
       AVG(pm.friend_count) AS avg_friends,
       AVG(pm.liked_post_count) AS avg_liked_posts,
       AVG(pm.liked_comment_count) AS avg_liked_comments,
       AVG(pm.interest_tag_count) AS avg_interest_tags,
       AVG(pm.study_university_count) AS avg_universities,
       AVG(pm.work_company_count) AS avg_companies
FROM person_metrics pm
JOIN place pl ON pm.location_city_id = pl.id
GROUP BY pl.name
ORDER BY avg_friends DESC
LIMIT 10
