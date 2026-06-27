WITH
forum_members AS (
  SELECT fm.forum_id,
         COUNT(DISTINCT fm.person_id) AS member_count
  FROM forum_has_member_person fm
  GROUP BY fm.forum_id
),
forum_posts AS (
  SELECT p.container_forum_id AS forum_id,
         COUNT(DISTINCT p.id) AS post_count,
         AVG(p.length) AS avg_post_length
  FROM post p
  GROUP BY p.container_forum_id
),
forum_comments AS (
  SELECT p.container_forum_id AS forum_id,
         COUNT(DISTINCT c.id) AS comment_count
  FROM post p
  JOIN comment c
    ON c.parent_post_id = p.id
  GROUP BY p.container_forum_id
),
forum_likes AS (
  SELECT p.container_forum_id AS forum_id,
         COUNT(plp.person_id) AS total_post_likes
  FROM post p
  JOIN person_likes_post plp
    ON plp.post_id = p.id
  GROUP BY p.container_forum_id
),
forum_tags AS (
  SELECT p.container_forum_id AS forum_id,
         COUNT(DISTINCT pt.tag_id) AS distinct_tag_count
  FROM post p
  JOIN post_has_tag_tag pt
    ON pt.post_id = p.id
  GROUP BY p.container_forum_id
)
SELECT
  f.id AS forum_id,
  f.title AS forum_title,
  COALESCE(fm.member_count, 0) AS member_count,
  COALESCE(fp.post_count, 0) AS post_count,
  fp.avg_post_length,
  COALESCE(fc.comment_count, 0) AS comment_count,
  COALESCE(fl.total_post_likes, 0) AS total_post_likes,
  COALESCE(ft.distinct_tag_count, 0) AS distinct_tag_count
FROM forum f
LEFT JOIN forum_members fm
  ON fm.forum_id = f.id
LEFT JOIN forum_posts fp
  ON fp.forum_id = f.id
LEFT JOIN forum_comments fc
  ON fc.forum_id = f.id
LEFT JOIN forum_likes fl
  ON fl.forum_id = f.id
LEFT JOIN forum_tags ft
  ON ft.forum_id = f.id
ORDER BY member_count DESC
LIMIT 10
