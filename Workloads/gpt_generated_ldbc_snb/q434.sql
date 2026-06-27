WITH post_stats AS (
  SELECT
    p.container_forum_id AS forum_id,
    COUNT(*) AS post_count,
    SUM(p.length) AS total_post_length,
    AVG(p.length) AS avg_post_length
  FROM post p
  GROUP BY p.container_forum_id
),
comment_stats AS (
  SELECT
    p.container_forum_id AS forum_id,
    COUNT(*) AS comment_count
  FROM comment c
  JOIN post p ON c.parent_post_id = p.id
  GROUP BY p.container_forum_id
),
post_like_stats AS (
  SELECT
    p.container_forum_id AS forum_id,
    COUNT(*) AS post_like_count,
    COUNT(DISTINCT plp.person_id) AS post_like_user_count
  FROM person_likes_post plp
  JOIN post p ON plp.post_id = p.id
  GROUP BY p.container_forum_id
),
comment_like_stats AS (
  SELECT
    p.container_forum_id AS forum_id,
    COUNT(*) AS comment_like_count,
    COUNT(DISTINCT plc.person_id) AS comment_like_user_count
  FROM person_likes_comment plc
  JOIN comment c ON plc.comment_id = c.id
  JOIN post p ON c.parent_post_id = p.id
  GROUP BY p.container_forum_id
),
member_stats AS (
  SELECT
    forum_id,
    COUNT(DISTINCT person_id) AS member_count
  FROM forum_has_member_person
  GROUP BY forum_id
),
tag_stats AS (
  SELECT
    forum_id,
    COUNT(DISTINCT tag_id) AS tag_count
  FROM forum_has_tag_tag
  GROUP BY forum_id
),
moderator_info AS (
  SELECT
    f.id AS forum_id,
    p.gender AS moderator_gender
  FROM forum f
  JOIN person p ON f.moderator_person_id = p.id
)
SELECT
  f.id AS forum_id,
  f.title AS forum_title,
  f.creation_date AS forum_creation_date,
  mi.moderator_gender,
  COALESCE(ps.post_count, 0) AS post_count,
  COALESCE(cs.comment_count, 0) AS comment_count,
  COALESCE(ps.total_post_length, 0) AS total_post_length,
  COALESCE(ps.avg_post_length, 0) AS avg_post_length,
  COALESCE(pls.post_like_count, 0) AS post_like_count,
  COALESCE(pls.post_like_user_count, 0) AS post_like_user_count,
  COALESCE(cls.comment_like_count, 0) AS comment_like_count,
  COALESCE(cls.comment_like_user_count, 0) AS comment_like_user_count,
  COALESCE(ms.member_count, 0) AS member_count,
  COALESCE(ts.tag_count, 0) AS tag_count
FROM forum f
LEFT JOIN moderator_info mi ON f.id = mi.forum_id
LEFT JOIN post_stats ps ON f.id = ps.forum_id
LEFT JOIN comment_stats cs ON f.id = cs.forum_id
LEFT JOIN post_like_stats pls ON f.id = pls.forum_id
LEFT JOIN comment_like_stats cls ON f.id = cls.forum_id
LEFT JOIN member_stats ms ON f.id = ms.forum_id
LEFT JOIN tag_stats ts ON f.id = ts.forum_id
ORDER BY post_like_count DESC
LIMIT 10
