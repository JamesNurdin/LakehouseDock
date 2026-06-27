WITH forum_stats AS (
  SELECT
    f.id AS forum_id,
    f.title AS forum_title,
    COUNT(DISTINCT p.id) AS post_count,
    AVG(p.length) AS avg_post_length,
    COUNT(DISTINCT c.id) AS comment_count,
    AVG(c.length) AS avg_comment_length,
    COUNT(plp.person_id) AS post_like_count,
    COUNT(plc.person_id) AS comment_like_count,
    COUNT(DISTINCT pt.tag_id) AS distinct_tag_count,
    COUNT(DISTINCT fm.person_id) AS member_count
  FROM forum f
  LEFT JOIN post p
    ON p.container_forum_id = f.id
  LEFT JOIN comment c
    ON c.parent_post_id = p.id
  LEFT JOIN person_likes_post plp
    ON plp.post_id = p.id
  LEFT JOIN person_likes_comment plc
    ON plc.comment_id = c.id
  LEFT JOIN post_has_tag_tag pt
    ON pt.post_id = p.id
  LEFT JOIN forum_has_member_person fm
    ON fm.forum_id = f.id
  GROUP BY f.id, f.title
)
SELECT
  forum_id,
  forum_title,
  post_count,
  avg_post_length,
  comment_count,
  avg_comment_length,
  post_like_count,
  comment_like_count,
  distinct_tag_count,
  member_count
FROM forum_stats
ORDER BY post_count DESC
LIMIT 10
