WITH forum_members AS (
  SELECT
    fm.forum_id,
    COUNT(DISTINCT fm.person_id) AS member_count
  FROM forum_has_member_person fm
  GROUP BY fm.forum_id
),
forum_posts AS (
  SELECT
    p.container_forum_id AS forum_id,
    COUNT(DISTINCT p.id) AS post_count,
    AVG(p.length) AS avg_post_length
  FROM post p
  GROUP BY p.container_forum_id
),
forum_likes AS (
  SELECT
    p.container_forum_id AS forum_id,
    COUNT(pl.person_id) AS total_post_likes
  FROM post p
  LEFT JOIN person_likes_post pl
    ON pl.post_id = p.id
  GROUP BY p.container_forum_id
),
forum_tags AS (
  SELECT
    ft.forum_id,
    COUNT(DISTINCT ft.tag_id) AS tag_count
  FROM forum_has_tag_tag ft
  GROUP BY ft.forum_id
)
SELECT
  f.id AS forum_id,
  f.title AS forum_title,
  mod.gender AS moderator_gender,
  COALESCE(fm.member_count, 0) AS member_count,
  COALESCE(fp.post_count, 0) AS post_count,
  fp.avg_post_length,
  COALESCE(fl.total_post_likes, 0) AS total_post_likes,
  COALESCE(ftg.tag_count, 0) AS tag_count
FROM forum f
JOIN person mod
  ON f.moderator_person_id = mod.id
LEFT JOIN forum_members fm
  ON fm.forum_id = f.id
LEFT JOIN forum_posts fp
  ON fp.forum_id = f.id
LEFT JOIN forum_likes fl
  ON fl.forum_id = f.id
LEFT JOIN forum_tags ftg
  ON ftg.forum_id = f.id
ORDER BY member_count DESC
LIMIT 10
