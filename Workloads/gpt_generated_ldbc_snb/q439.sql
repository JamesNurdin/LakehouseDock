WITH forum_base AS (
  SELECT f.id AS forum_id,
         f.title AS forum_title,
         mod_p.first_name AS moderator_first_name,
         mod_p.last_name AS moderator_last_name
  FROM forum f
  LEFT JOIN person mod_p
    ON f.moderator_person_id = mod_p.id
),
post_metrics AS (
  SELECT p.container_forum_id AS forum_id,
         COUNT(*) AS post_count,
         COALESCE(SUM(p.length), 0) AS total_post_length,
         COALESCE(AVG(p.length), 0) AS avg_post_length
  FROM post p
  GROUP BY p.container_forum_id
),
post_likes AS (
  SELECT p.container_forum_id AS forum_id,
         COUNT(plp.person_id) AS total_post_likes
  FROM post p
  LEFT JOIN person_likes_post plp
    ON plp.post_id = p.id
  GROUP BY p.container_forum_id
),
comment_metrics AS (
  SELECT p.container_forum_id AS forum_id,
         COUNT(c.id) AS comment_count,
         COALESCE(SUM(c.length), 0) AS total_comment_length,
         COALESCE(AVG(c.length), 0) AS avg_comment_length
  FROM post p
  LEFT JOIN comment c
    ON c.parent_post_id = p.id
  GROUP BY p.container_forum_id
),
member_counts AS (
  SELECT fhm.forum_id,
         COUNT(DISTINCT fhm.person_id) AS member_count
  FROM forum_has_member_person fhm
  GROUP BY fhm.forum_id
),
tag_counts AS (
  SELECT p.container_forum_id AS forum_id,
         COUNT(DISTINCT pt.tag_id) AS distinct_tag_count
  FROM post p
  LEFT JOIN post_has_tag_tag pt
    ON pt.post_id = p.id
  GROUP BY p.container_forum_id
)
SELECT
  fb.forum_id,
  fb.forum_title,
  fb.moderator_first_name,
  fb.moderator_last_name,
  COALESCE(pm.post_count, 0) AS post_count,
  COALESCE(pm.total_post_length, 0) AS total_post_length,
  COALESCE(pm.avg_post_length, 0) AS avg_post_length,
  COALESCE(pl.total_post_likes, 0) AS total_post_likes,
  CASE
    WHEN COALESCE(pm.post_count, 0) = 0 THEN 0
    ELSE CAST(COALESCE(pl.total_post_likes, 0) AS double) / pm.post_count
  END AS avg_likes_per_post,
  COALESCE(cm.comment_count, 0) AS comment_count,
  COALESCE(cm.total_comment_length, 0) AS total_comment_length,
  COALESCE(cm.avg_comment_length, 0) AS avg_comment_length,
  COALESCE(mc.member_count, 0) AS member_count,
  COALESCE(tc.distinct_tag_count, 0) AS distinct_tag_count
FROM forum_base fb
LEFT JOIN post_metrics pm      ON pm.forum_id = fb.forum_id
LEFT JOIN post_likes pl        ON pl.forum_id = fb.forum_id
LEFT JOIN comment_metrics cm   ON cm.forum_id = fb.forum_id
LEFT JOIN member_counts mc     ON mc.forum_id = fb.forum_id
LEFT JOIN tag_counts tc        ON tc.forum_id = fb.forum_id
ORDER BY post_count DESC
LIMIT 100
