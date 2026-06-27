WITH forum_info AS (
  SELECT f.id AS forum_id,
         f.title AS forum_title,
         mod.first_name AS moderator_first_name,
         mod.last_name AS moderator_last_name
  FROM forum f
  LEFT JOIN person mod ON f.moderator_person_id = mod.id
),
member_metrics AS (
  SELECT m.forum_id,
         COUNT(DISTINCT m.person_id) AS member_count,
         COUNT(DISTINCT w.company_id) AS distinct_member_companies
  FROM forum_has_member_person m
  LEFT JOIN person p ON m.person_id = p.id
  LEFT JOIN person_work_at_company w ON w.person_id = p.id
  GROUP BY m.forum_id
),
post_metrics AS (
  SELECT po.container_forum_id AS forum_id,
         COUNT(DISTINCT po.id) AS post_count,
         AVG(po.length) AS avg_post_length
  FROM post po
  GROUP BY po.container_forum_id
),
like_metrics AS (
  SELECT po.container_forum_id AS forum_id,
         COUNT(l.person_id) AS total_likes,
         COUNT(DISTINCT l.person_id) AS distinct_likers
  FROM post po
  LEFT JOIN person_likes_post l ON l.post_id = po.id
  GROUP BY po.container_forum_id
),
tag_metrics AS (
  SELECT ft.forum_id,
         COUNT(DISTINCT ft.tag_id) AS tag_count
  FROM forum_has_tag_tag ft
  GROUP BY ft.forum_id
)
SELECT fi.forum_id,
       fi.forum_title,
       fi.moderator_first_name,
       fi.moderator_last_name,
       COALESCE(mm.member_count, 0) AS member_count,
       COALESCE(mm.distinct_member_companies, 0) AS distinct_member_companies,
       COALESCE(pm.post_count, 0) AS post_count,
       COALESCE(pm.avg_post_length, 0) AS avg_post_length,
       COALESCE(lm.total_likes, 0) AS total_likes,
       COALESCE(lm.distinct_likers, 0) AS distinct_likers,
       COALESCE(tm.tag_count, 0) AS tag_count
FROM forum_info fi
LEFT JOIN member_metrics mm ON mm.forum_id = fi.forum_id
LEFT JOIN post_metrics pm ON pm.forum_id = fi.forum_id
LEFT JOIN like_metrics lm ON lm.forum_id = fi.forum_id
LEFT JOIN tag_metrics tm ON tm.forum_id = fi.forum_id
ORDER BY total_likes DESC
LIMIT 100
