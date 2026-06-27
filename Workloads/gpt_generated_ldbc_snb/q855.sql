SELECT
  f.id AS forum_id,
  f.title AS forum_title,
  COUNT(DISTINCT po.id) AS post_count,
  COUNT(DISTINCT c.id) AS comment_count,
  AVG(c.length) AS avg_comment_length,
  COUNT(DISTINCT CASE WHEN
    EXISTS (
      SELECT 1
      FROM person_study_at_university psu
      JOIN organisation o ON psu.university_id = o.id
      WHERE psu.person_id = p.id
        AND o.type = 'University'
    )
    AND EXISTS (
      SELECT 1
      FROM person_has_interest_tag pht
      WHERE pht.person_id = p.id
        AND pht.tag_id = 123
    )
    THEN p.id END) AS student_commenter_count
FROM forum f
LEFT JOIN post po ON po.container_forum_id = f.id
LEFT JOIN comment c ON c.parent_post_id = po.id
LEFT JOIN person p ON c.creator_person_id = p.id
GROUP BY f.id, f.title
ORDER BY comment_count DESC
LIMIT 10
