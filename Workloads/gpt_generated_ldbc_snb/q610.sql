WITH
  friend_edges AS (
    SELECT person1_id AS person_id FROM person_knows_person
    UNION ALL
    SELECT person2_id AS person_id FROM person_knows_person
  ),
  friend_counts AS (
    SELECT person_id, COUNT(*) AS friend_count
    FROM friend_edges
    GROUP BY person_id
  ),
  likes_counts AS (
    SELECT person_id, COUNT(*) AS likes_count
    FROM person_likes_comment
    GROUP BY person_id
  ),
  study_agg AS (
    SELECT person_id, AVG(class_year) AS avg_class_year
    FROM person_study_at_university
    GROUP BY person_id
  ),
  work_agg AS (
    SELECT person_id, AVG(work_from) AS avg_work_from
    FROM person_work_at_company
    GROUP BY person_id
  )
SELECT
  fhmp.forum_id,
  COUNT(DISTINCT p.id) AS member_count,
  AVG(COALESCE(fc.friend_count, 0)) AS avg_friend_count,
  AVG(COALESCE(lc.likes_count, 0)) AS avg_likes_count,
  100.0 * SUM(CASE WHEN p.gender = 'male' THEN 1 ELSE 0 END) / COUNT(*) AS male_percentage,
  AVG(sa.avg_class_year) AS avg_member_class_year,
  AVG(wa.avg_work_from) AS avg_member_work_from
FROM forum_has_member_person AS fhmp
JOIN person AS p
  ON fhmp.person_id = p.id
LEFT JOIN friend_counts AS fc
  ON p.id = fc.person_id
LEFT JOIN likes_counts AS lc
  ON p.id = lc.person_id
LEFT JOIN study_agg AS sa
  ON p.id = sa.person_id
LEFT JOIN work_agg AS wa
  ON p.id = wa.person_id
GROUP BY fhmp.forum_id
ORDER BY fhmp.forum_id
