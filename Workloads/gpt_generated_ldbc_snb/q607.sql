WITH forum_stats AS (
  SELECT
    f.id AS forum_id,
    f.title AS forum_title,
    f.creation_date AS forum_creation_date,
    mod.first_name AS moderator_first_name,
    mod.last_name AS moderator_last_name,
    COUNT(DISTINCT p.id) AS post_count,
    AVG(p.length) AS avg_post_length,
    COUNT(plp.person_id) AS total_likes,
    COUNT(DISTINCT plp.person_id) AS distinct_like_user_count,
    COUNT(DISTINCT c.id) AS comment_count,
    COUNT(DISTINCT ph.tag_id) AS distinct_tag_count
  FROM forum f
  LEFT JOIN person mod ON f.moderator_person_id = mod.id
  LEFT JOIN post p ON p.container_forum_id = f.id
  LEFT JOIN person_likes_post plp ON plp.post_id = p.id
  LEFT JOIN comment c ON c.parent_post_id = p.id
  LEFT JOIN post_has_tag_tag ph ON ph.post_id = p.id
  GROUP BY f.id, f.title, f.creation_date, mod.first_name, mod.last_name
)
SELECT
  forum_id,
  forum_title,
  forum_creation_date,
  moderator_first_name,
  moderator_last_name,
  post_count,
  avg_post_length,
  total_likes,
  distinct_like_user_count,
  comment_count,
  distinct_tag_count
FROM forum_stats
ORDER BY post_count DESC
LIMIT 10
