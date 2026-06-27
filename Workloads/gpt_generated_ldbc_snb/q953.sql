WITH comment_stats AS (
   SELECT
       su.university_id,
       p.gender,
       COUNT(c.id) AS comment_count,
       AVG(c.length) AS avg_comment_length
   FROM person_study_at_university su
   JOIN person p ON su.person_id = p.id
   JOIN comment c ON c.creator_person_id = p.id
   GROUP BY su.university_id, p.gender
),
comment_like_stats AS (
   SELECT
       su.university_id,
       p.gender,
       COUNT(lc.person_id) AS comment_like_total
   FROM person_study_at_university su
   JOIN person p ON su.person_id = p.id
   JOIN comment c ON c.creator_person_id = p.id
   LEFT JOIN person_likes_comment lc ON lc.comment_id = c.id
   GROUP BY su.university_id, p.gender
),
post_like_stats AS (
   SELECT
       su.university_id,
       p.gender,
       COUNT(lp.person_id) AS post_like_total
   FROM person_study_at_university su
   JOIN person p ON su.person_id = p.id
   LEFT JOIN person_likes_post lp ON lp.person_id = p.id
   GROUP BY su.university_id, p.gender
)
SELECT
   cs.university_id,
   cs.gender,
   cs.comment_count,
   cs.avg_comment_length,
   COALESCE(cls.comment_like_total, 0) AS total_comment_likes,
   COALESCE(pls.post_like_total, 0) AS total_post_likes_by_students
FROM comment_stats cs
LEFT JOIN comment_like_stats cls
   ON cls.university_id = cs.university_id AND cls.gender = cs.gender
LEFT JOIN post_like_stats pls
   ON pls.university_id = cs.university_id AND pls.gender = cs.gender
ORDER BY total_comment_likes DESC, cs.university_id, cs.gender
