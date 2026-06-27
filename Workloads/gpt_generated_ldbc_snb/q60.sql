WITH person_univ AS (
    SELECT p.id,
           p.gender,
           psu.university_id,
           psu.class_year
    FROM person p
    JOIN person_study_at_university psu
      ON p.id = psu.person_id
),
comment_stats AS (
    SELECT c.creator_person_id,
           COUNT(*) AS comment_cnt,
           SUM(c.length) AS comment_len_sum
    FROM comment c
    GROUP BY c.creator_person_id
),
forum_stats AS (
    SELECT f.moderator_person_id,
           COUNT(*) AS forum_cnt
    FROM forum f
    GROUP BY f.moderator_person_id
)
SELECT pu.university_id,
       COUNT(DISTINCT pu.id) AS total_students,
       SUM(COALESCE(cs.comment_cnt, 0)) AS total_comments,
       CASE WHEN SUM(COALESCE(cs.comment_cnt, 0)) > 0
            THEN SUM(COALESCE(cs.comment_len_sum, 0)) / SUM(COALESCE(cs.comment_cnt, 0))
            ELSE NULL
       END AS avg_comment_length,
       SUM(COALESCE(fs.forum_cnt, 0)) AS total_forums_moderated,
       SUM(CASE WHEN pu.gender = 'male'   THEN 1 ELSE 0 END) AS male_students,
       SUM(CASE WHEN pu.gender = 'female' THEN 1 ELSE 0 END) AS female_students
FROM person_univ pu
LEFT JOIN comment_stats cs
       ON cs.creator_person_id = pu.id
LEFT JOIN forum_stats fs
       ON fs.moderator_person_id = pu.id
GROUP BY pu.university_id
ORDER BY pu.university_id
