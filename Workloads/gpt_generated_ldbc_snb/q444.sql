WITH member_counts AS (
   SELECT f.id AS forum_id,
          COUNT(DISTINCT fm.person_id) AS member_count
   FROM forum f
   LEFT JOIN forum_has_member_person fm
     ON fm.forum_id = f.id
   GROUP BY f.id
),
post_counts AS (
   SELECT f.id AS forum_id,
          COUNT(DISTINCT p.id) AS post_count
   FROM forum f
   LEFT JOIN post p
     ON p.container_forum_id = f.id
   GROUP BY f.id
),
comment_stats AS (
   SELECT f.id AS forum_id,
          COUNT(DISTINCT c.id) AS comment_count,
          AVG(c.length) AS avg_comment_length
   FROM forum f
   LEFT JOIN post p
     ON p.container_forum_id = f.id
   LEFT JOIN comment c
     ON c.parent_post_id = p.id
   GROUP BY f.id
),
post_like_counts AS (
   SELECT f.id AS forum_id,
          COUNT(plp.person_id) AS total_post_likes
   FROM forum f
   LEFT JOIN post p
     ON p.container_forum_id = f.id
   LEFT JOIN person_likes_post plp
     ON plp.post_id = p.id
   GROUP BY f.id
),
comment_like_counts AS (
   SELECT f.id AS forum_id,
          COUNT(plc.person_id) AS total_comment_likes
   FROM forum f
   LEFT JOIN post p
     ON p.container_forum_id = f.id
   LEFT JOIN comment c
     ON c.parent_post_id = p.id
   LEFT JOIN person_likes_comment plc
     ON plc.comment_id = c.id
   GROUP BY f.id
),
forum_tags AS (
   SELECT f.id AS forum_id,
          ARRAY_AGG(DISTINCT ft.tag_id) AS tags
   FROM forum f
   LEFT JOIN forum_has_tag_tag ft
     ON ft.forum_id = f.id
   GROUP BY f.id
)
SELECT
   f.id AS forum_id,
   f.title AS forum_title,
   mod.first_name AS moderator_first_name,
   mod.last_name AS moderator_last_name,
   COALESCE(m.member_count, 0) AS member_count,
   COALESCE(p.post_count, 0) AS post_count,
   COALESCE(c.comment_count, 0) AS comment_count,
   COALESCE(pl.total_post_likes, 0) AS total_post_likes,
   COALESCE(cl.total_comment_likes, 0) AS total_comment_likes,
   c.avg_comment_length,
   t.tags AS forum_tags
FROM forum f
LEFT JOIN person mod
  ON f.moderator_person_id = mod.id
LEFT JOIN member_counts m
  ON m.forum_id = f.id
LEFT JOIN post_counts p
  ON p.forum_id = f.id
LEFT JOIN comment_stats c
  ON c.forum_id = f.id
LEFT JOIN post_like_counts pl
  ON pl.forum_id = f.id
LEFT JOIN comment_like_counts cl
  ON cl.forum_id = f.id
LEFT JOIN forum_tags t
  ON t.forum_id = f.id
ORDER BY member_count DESC
LIMIT 10
