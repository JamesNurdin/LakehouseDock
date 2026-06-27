WITH post_stats AS (
   SELECT
       p.container_forum_id AS forum_id,
       COUNT(*) AS post_count,
       AVG(p.length) AS avg_post_length,
       COUNT(pl.person_id) AS post_like_count
   FROM post p
   LEFT JOIN person_likes_post pl
       ON pl.post_id = p.id
   GROUP BY p.container_forum_id
),
comment_stats AS (
   SELECT
       p.container_forum_id AS forum_id,
       COUNT(*) AS comment_count,
       AVG(c.length) AS avg_comment_length,
       COUNT(cl.person_id) AS comment_like_count
   FROM comment c
   JOIN post p
       ON c.parent_post_id = p.id
   LEFT JOIN person_likes_comment cl
       ON cl.comment_id = c.id
   GROUP BY p.container_forum_id
),
member_stats AS (
   SELECT
       fhm.forum_id,
       COUNT(DISTINCT fhm.person_id) AS member_count
   FROM forum_has_member_person fhm
   GROUP BY fhm.forum_id
)
SELECT
   f.id AS forum_id,
   f.title,
   mod.first_name AS moderator_first_name,
   mod.last_name AS moderator_last_name,
   COALESCE(ps.post_count, 0) AS post_count,
   COALESCE(ps.avg_post_length, 0) AS avg_post_length,
   COALESCE(ps.post_like_count, 0) AS post_like_count,
   COALESCE(cs.comment_count, 0) AS comment_count,
   COALESCE(cs.avg_comment_length, 0) AS avg_comment_length,
   COALESCE(cs.comment_like_count, 0) AS comment_like_count,
   COALESCE(ms.member_count, 0) AS member_count,
   (COALESCE(ps.post_like_count, 0) + COALESCE(cs.comment_like_count, 0)) AS total_like_count,
   (COALESCE(ps.post_count, 0) + COALESCE(cs.comment_count, 0)) AS total_activity_count
FROM forum f
LEFT JOIN person mod
   ON mod.id = f.moderator_person_id
LEFT JOIN post_stats ps
   ON ps.forum_id = f.id
LEFT JOIN comment_stats cs
   ON cs.forum_id = f.id
LEFT JOIN member_stats ms
   ON ms.forum_id = f.id
ORDER BY total_activity_count DESC, total_like_count DESC
LIMIT 10
