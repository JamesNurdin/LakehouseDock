-- Analytical query: per‑forum member statistics
SELECT
    fhm.forum_id,
    COUNT(DISTINCT p.id) AS member_count,
    AVG(date_diff('year', CAST(DATE_PARSE(p.birthday, '%Y-%m-%d') AS DATE), CURRENT_DATE)) AS avg_age,
    AVG(COALESCE(l.likes_cnt, 0)) AS avg_likes_per_member,
    AVG(COALESCE(s.studied_flag, 0)) AS pct_members_studied_at_university,
    AVG(COALESCE(w.worked_flag, 0)) AS pct_members_work_at_company,
    SUM(CASE WHEN p.gender = 'male'   THEN 1 ELSE 0 END) * 100.0 / COUNT(DISTINCT p.id) AS pct_male,
    SUM(CASE WHEN p.gender = 'female' THEN 1 ELSE 0 END) * 100.0 / COUNT(DISTINCT p.id) AS pct_female
FROM forum_has_member_person fhm
JOIN person p
    ON fhm.person_id = p.id
LEFT JOIN (
    SELECT person_id, COUNT(comment_id) AS likes_cnt
    FROM person_likes_comment
    GROUP BY person_id
) l
    ON p.id = l.person_id
LEFT JOIN (
    SELECT person_id, 1 AS studied_flag
    FROM person_study_at_university
    GROUP BY person_id
) s
    ON p.id = s.person_id
LEFT JOIN (
    SELECT person_id, 1 AS worked_flag
    FROM person_work_at_company
    GROUP BY person_id
) w
    ON p.id = w.person_id
GROUP BY fhm.forum_id
ORDER BY member_count DESC
LIMIT 10
