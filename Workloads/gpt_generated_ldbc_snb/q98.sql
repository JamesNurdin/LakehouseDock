WITH
  friends AS (
    SELECT p.id AS person_id,
           pkp.person2_id AS friend_id
    FROM person p
    JOIN person_knows_person pkp ON pkp.person1_id = p.id
    UNION ALL
    SELECT p.id AS person_id,
           pkp.person1_id AS friend_id
    FROM person p
    JOIN person_knows_person pkp ON pkp.person2_id = p.id
  ),
  friend_counts AS (
    SELECT person_id,
           COUNT(DISTINCT friend_id) AS friend_count
    FROM friends
    GROUP BY person_id
  ),
  post_stats AS (
    SELECT p.id AS person_id,
           COUNT(DISTINCT po.id) AS post_count,
           COUNT(plike.person_id) AS likes_on_posts
    FROM person p
    LEFT JOIN post po ON po.creator_person_id = p.id
    LEFT JOIN person_likes_post plike ON plike.post_id = po.id
    GROUP BY p.id
  ),
  comment_stats AS (
    SELECT p.id AS person_id,
           COUNT(DISTINCT c.id) AS comment_count,
           COUNT(clike.person_id) AS likes_on_comments
    FROM person p
    LEFT JOIN comment c ON c.creator_person_id = p.id
    LEFT JOIN person_likes_comment clike ON clike.comment_id = c.id
    GROUP BY p.id
  ),
  work_stats AS (
    SELECT p.id AS person_id,
           COUNT(DISTINCT pwc.company_id) AS company_count
    FROM person p
    LEFT JOIN person_work_at_company pwc ON pwc.person_id = p.id
    GROUP BY p.id
  ),
  study_stats AS (
    SELECT p.id AS person_id,
           COUNT(DISTINCT psu.university_id) AS university_count
    FROM person p
    LEFT JOIN person_study_at_university psu ON psu.person_id = p.id
    GROUP BY p.id
  )
SELECT
  p.id AS person_id,
  p.first_name,
  p.last_name,
  pl.name AS city_name,
  COALESCE(fc.friend_count, 0) AS friend_count,
  COALESCE(ps.post_count, 0) AS post_count,
  COALESCE(ps.likes_on_posts, 0) AS likes_on_posts,
  CASE WHEN COALESCE(ps.post_count, 0) = 0 THEN 0
       ELSE (ps.likes_on_posts * 1.0) / ps.post_count END AS avg_likes_per_post,
  COALESCE(cs.comment_count, 0) AS comment_count,
  COALESCE(cs.likes_on_comments, 0) AS likes_on_comments,
  CASE WHEN COALESCE(cs.comment_count, 0) = 0 THEN 0
       ELSE (cs.likes_on_comments * 1.0) / cs.comment_count END AS avg_likes_per_comment,
  COALESCE(ws.company_count, 0) AS company_count,
  COALESCE(ss.university_count, 0) AS university_count
FROM person p
LEFT JOIN place pl ON p.location_city_id = pl.id
LEFT JOIN friend_counts fc ON p.id = fc.person_id
LEFT JOIN post_stats ps ON p.id = ps.person_id
LEFT JOIN comment_stats cs ON p.id = cs.person_id
LEFT JOIN work_stats ws ON p.id = ws.person_id
LEFT JOIN study_stats ss ON p.id = ss.person_id
ORDER BY friend_count DESC, likes_on_posts DESC
LIMIT 100
