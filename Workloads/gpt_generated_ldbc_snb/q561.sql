WITH forum_stats AS (
  SELECT
    f.id AS forum_id,
    f.title AS forum_title,
    COUNT(DISTINCT p.id) AS post_count,
    SUM(p.length) AS total_post_length,
    AVG(p.length) AS avg_post_length,
    COUNT(plp.person_id) AS total_like_count,
    COUNT(DISTINCT plp.person_id) AS distinct_like_user_count,
    COUNT(DISTINCT c.id) AS comment_count,
    SUM(c.length) AS total_comment_length,
    AVG(c.length) AS avg_comment_length,
    COUNT(DISTINCT pht.tag_id) AS distinct_tag_count,
    COUNT(DISTINCT p_creator.id) AS distinct_post_creator_count,
    COUNT(DISTINCT c_creator.id) AS distinct_comment_creator_count,
    COUNT(DISTINCT mod_person.id) AS distinct_moderator_count
  FROM forum f
  LEFT JOIN post p ON p.container_forum_id = f.id
  LEFT JOIN person p_creator ON p.creator_person_id = p_creator.id
  LEFT JOIN person_likes_post plp ON plp.post_id = p.id
  LEFT JOIN post_has_tag_tag pht ON pht.post_id = p.id
  LEFT JOIN comment c ON c.parent_post_id = p.id
  LEFT JOIN person c_creator ON c.creator_person_id = c_creator.id
  LEFT JOIN person mod_person ON f.moderator_person_id = mod_person.id
  GROUP BY f.id, f.title
)
SELECT
  forum_id,
  forum_title,
  post_count,
  total_post_length,
  avg_post_length,
  total_like_count,
  distinct_like_user_count,
  comment_count,
  total_comment_length,
  avg_comment_length,
  distinct_tag_count,
  distinct_post_creator_count,
  distinct_comment_creator_count,
  distinct_moderator_count
FROM forum_stats
ORDER BY post_count DESC
LIMIT 10
