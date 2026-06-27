WITH
  forum_members AS (
    SELECT
      fm.forum_id,
      COUNT(DISTINCT fm.person_id) AS member_count
    FROM forum_has_member_person fm
    GROUP BY fm.forum_id
  ),
  forum_posts AS (
    SELECT
      p.container_forum_id AS forum_id,
      COUNT(*) AS post_count,
      AVG(p.length) AS avg_post_length
    FROM post p
    GROUP BY p.container_forum_id
  ),
  post_likes AS (
    SELECT
      p.container_forum_id AS forum_id,
      COUNT(*) AS post_like_count
    FROM post p
    JOIN person_likes_post plc ON plc.post_id = p.id
    GROUP BY p.container_forum_id
  ),
  forum_comments AS (
    SELECT
      p.container_forum_id AS forum_id,
      COUNT(*) AS comment_count,
      AVG(c.length) AS avg_comment_length
    FROM post p
    JOIN comment c ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
  ),
  comment_likes AS (
    SELECT
      p.container_forum_id AS forum_id,
      COUNT(*) AS comment_like_count
    FROM post p
    JOIN comment c ON c.parent_post_id = p.id
    JOIN person_likes_comment plc ON plc.comment_id = c.id
    GROUP BY p.container_forum_id
  ),
  comment_tags AS (
    SELECT
      p.container_forum_id AS forum_id,
      COUNT(DISTINCT cht.tag_id) AS distinct_tag_count
    FROM post p
    JOIN comment c ON c.parent_post_id = p.id
    JOIN comment_has_tag_tag cht ON cht.comment_id = c.id
    GROUP BY p.container_forum_id
  )
SELECT
  f.id AS forum_id,
  f.title AS forum_title,
  COALESCE(fm.member_count, 0)           AS member_count,
  COALESCE(fp.post_count, 0)            AS post_count,
  COALESCE(fp.avg_post_length, 0)       AS avg_post_length,
  COALESCE(fc.comment_count, 0)         AS comment_count,
  COALESCE(fc.avg_comment_length, 0)    AS avg_comment_length,
  COALESCE(pl.post_like_count, 0)       AS post_like_count,
  COALESCE(cl.comment_like_count, 0)    AS comment_like_count,
  COALESCE(ct.distinct_tag_count, 0)    AS distinct_tag_count,
  (
    COALESCE(pl.post_like_count, 0) +
    COALESCE(cl.comment_like_count, 0) +
    COALESCE(fc.comment_count, 0) +
    COALESCE(fp.post_count, 0)
  )                                      AS total_engagement
FROM forum f
LEFT JOIN forum_members   fm ON fm.forum_id = f.id
LEFT JOIN forum_posts     fp ON fp.forum_id = f.id
LEFT JOIN post_likes      pl ON pl.forum_id = f.id
LEFT JOIN forum_comments  fc ON fc.forum_id = f.id
LEFT JOIN comment_likes   cl ON cl.forum_id = f.id
LEFT JOIN comment_tags    ct ON ct.forum_id = f.id
ORDER BY total_engagement DESC
LIMIT 10
