WITH forum_members AS (
  SELECT f.id AS forum_id,
         COUNT(DISTINCT fm.person_id) AS member_count
  FROM forum f
  JOIN forum_has_member_person fm ON fm.forum_id = f.id
  GROUP BY f.id
),
post_stats AS (
  SELECT f.id AS forum_id,
         COUNT(p.id) AS post_count,
         AVG(p.length) AS avg_post_length
  FROM forum f
  JOIN post p ON p.container_forum_id = f.id
  GROUP BY f.id
),
comment_stats AS (
  SELECT f.id AS forum_id,
         COUNT(c.id) AS comment_count,
         AVG(c.length) AS avg_comment_length
  FROM forum f
  JOIN post p ON p.container_forum_id = f.id
  JOIN comment c ON c.parent_post_id = p.id
  GROUP BY f.id
),
post_like_stats AS (
  SELECT f.id AS forum_id,
         COUNT(plp.person_id) AS post_like_count
  FROM forum f
  JOIN post p ON p.container_forum_id = f.id
  JOIN person_likes_post plp ON plp.post_id = p.id
  GROUP BY f.id
),
comment_like_stats AS (
  SELECT f.id AS forum_id,
         COUNT(plc.person_id) AS comment_like_count
  FROM forum f
  JOIN post p ON p.container_forum_id = f.id
  JOIN comment c ON c.parent_post_id = p.id
  JOIN person_likes_comment plc ON plc.comment_id = c.id
  GROUP BY f.id
)
SELECT f.id AS forum_id,
       f.title AS forum_title,
       p_mod.first_name AS moderator_first_name,
       p_mod.last_name AS moderator_last_name,
       COALESCE(fm.member_count, 0) AS member_count,
       COALESCE(ps.post_count, 0) AS post_count,
       COALESCE(ps.avg_post_length, 0) AS avg_post_length,
       COALESCE(cs.comment_count, 0) AS comment_count,
       COALESCE(cs.avg_comment_length, 0) AS avg_comment_length,
       COALESCE(pls.post_like_count, 0) AS post_like_count,
       COALESCE(cls.comment_like_count, 0) AS comment_like_count,
       (COALESCE(pls.post_like_count, 0) + COALESCE(cls.comment_like_count, 0)) AS total_like_count
FROM forum f
LEFT JOIN person p_mod ON p_mod.id = f.moderator_person_id
LEFT JOIN forum_members fm ON fm.forum_id = f.id
LEFT JOIN post_stats ps ON ps.forum_id = f.id
LEFT JOIN comment_stats cs ON cs.forum_id = f.id
LEFT JOIN post_like_stats pls ON pls.forum_id = f.id
LEFT JOIN comment_like_stats cls ON cls.forum_id = f.id
ORDER BY total_like_count DESC
LIMIT 10
