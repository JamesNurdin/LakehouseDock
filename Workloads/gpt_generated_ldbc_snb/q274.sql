/*
  Analytical query: Top 10 forums by average likes per member on comments.
  Metrics per forum include:
    • Forum title and moderator name
    • Number of members
    • Number of comments and their average length
    • Total likes on comments
    • Number of distinct tags used in comments
    • Likes per comment and likes per member ratios
*/
WITH members AS (
  SELECT
    forum_id,
    COUNT(DISTINCT person_id) AS member_count
  FROM forum_has_member_person
  GROUP BY forum_id
),
comments AS (
  SELECT
    f.id AS forum_id,
    COUNT(DISTINCT c.id) AS comment_count,
    AVG(c.length) AS avg_comment_length
  FROM forum f
  JOIN post p ON p.container_forum_id = f.id
  JOIN comment c ON c.parent_post_id = p.id
  GROUP BY f.id
),
likes AS (
  SELECT
    f.id AS forum_id,
    COUNT(plc.person_id) AS total_likes
  FROM forum f
  JOIN post p ON p.container_forum_id = f.id
  JOIN comment c ON c.parent_post_id = p.id
  JOIN person_likes_comment plc ON plc.comment_id = c.id
  GROUP BY f.id
),
tags AS (
  SELECT
    f.id AS forum_id,
    COUNT(DISTINCT cht.tag_id) AS distinct_tag_count
  FROM forum f
  JOIN post p ON p.container_forum_id = f.id
  JOIN comment c ON c.parent_post_id = p.id
  JOIN comment_has_tag_tag cht ON cht.comment_id = c.id
  GROUP BY f.id
),
moderators AS (
  SELECT
    f.id AS forum_id,
    f.title,
    p.first_name AS moderator_first_name,
    p.last_name AS moderator_last_name
  FROM forum f
  JOIN person p ON f.moderator_person_id = p.id
)
SELECT
  mod.forum_id,
  mod.title,
  mod.moderator_first_name,
  mod.moderator_last_name,
  COALESCE(mem.member_count, 0) AS member_count,
  COALESCE(com.comment_count, 0) AS comment_count,
  com.avg_comment_length,
  COALESCE(lk.total_likes, 0) AS total_likes,
  COALESCE(tg.distinct_tag_count, 0) AS distinct_tag_count,
  CASE WHEN com.comment_count > 0 THEN CAST(COALESCE(lk.total_likes, 0) AS double) / com.comment_count ELSE NULL END AS likes_per_comment,
  CASE WHEN COALESCE(mem.member_count, 0) > 0 THEN CAST(COALESCE(lk.total_likes, 0) AS double) / mem.member_count ELSE NULL END AS likes_per_member
FROM moderators mod
LEFT JOIN members mem       ON mem.forum_id       = mod.forum_id
LEFT JOIN comments com      ON com.forum_id      = mod.forum_id
LEFT JOIN likes lk          ON lk.forum_id       = mod.forum_id
LEFT JOIN tags tg           ON tg.forum_id       = mod.forum_id
ORDER BY likes_per_member DESC
LIMIT 10
