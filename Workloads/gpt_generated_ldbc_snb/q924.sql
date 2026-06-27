WITH comment_stats AS (
    SELECT creator_person_id AS person_id,
           COUNT(*) AS comment_count,
           SUM(length) AS total_comment_length
    FROM comment
    GROUP BY creator_person_id
),
likes_given AS (
    SELECT person_id,
           COUNT(*) AS likes_given
    FROM person_likes_comment
    GROUP BY person_id
),
likes_received AS (
    SELECT c.creator_person_id AS person_id,
           COUNT(*) AS likes_received
    FROM comment c
    JOIN person_likes_comment plc ON c.id = plc.comment_id
    GROUP BY c.creator_person_id
),
post_stats AS (
    SELECT creator_person_id AS person_id,
           COUNT(*) AS post_count
    FROM post
    GROUP BY creator_person_id
),
forum_membership AS (
    SELECT person_id,
           COUNT(DISTINCT forum_id) AS forum_membership_count
    FROM forum_has_member_person
    GROUP BY person_id
),
study_universities AS (
    SELECT person_id,
           COUNT(DISTINCT university_id) AS university_count
    FROM person_study_at_university
    GROUP BY person_id
),
work_companies AS (
    SELECT person_id,
           COUNT(DISTINCT company_id) AS company_count
    FROM person_work_at_company
    GROUP BY person_id
)
SELECT
    p.id AS person_id,
    p.first_name,
    p.last_name,
    COALESCE(cs.comment_count, 0) AS comment_count,
    COALESCE(cs.total_comment_length, 0) AS total_comment_length,
    CASE WHEN COALESCE(cs.comment_count, 0) > 0
         THEN COALESCE(cs.total_comment_length, 0) / COALESCE(cs.comment_count, 0)
         ELSE NULL
    END AS avg_comment_length,
    COALESCE(lg.likes_given, 0) AS likes_given,
    COALESCE(lr.likes_received, 0) AS likes_received,
    COALESCE(ps.post_count, 0) AS post_count,
    COALESCE(fm.forum_membership_count, 0) AS forum_membership_count,
    COALESCE(su.university_count, 0) AS university_count,
    COALESCE(wc.company_count, 0) AS company_count
FROM person p
LEFT JOIN comment_stats cs ON p.id = cs.person_id
LEFT JOIN likes_given lg ON p.id = lg.person_id
LEFT JOIN likes_received lr ON p.id = lr.person_id
LEFT JOIN post_stats ps ON p.id = ps.person_id
LEFT JOIN forum_membership fm ON p.id = fm.person_id
LEFT JOIN study_universities su ON p.id = su.person_id
LEFT JOIN work_companies wc ON p.id = wc.person_id
ORDER BY likes_received DESC
LIMIT 100
