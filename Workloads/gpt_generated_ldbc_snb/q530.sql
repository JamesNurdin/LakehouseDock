WITH
  post_likes AS (
    SELECT
      plp.post_id,
      COUNT(plp.person_id) AS like_count,
      COUNT(DISTINCT plp.person_id) AS distinct_likers
    FROM person_likes_post plp
    GROUP BY plp.post_id
  ),
  post_comments AS (
    SELECT
      c.parent_post_id AS post_id,
      COUNT(c.id) AS comment_count,
      SUM(c.length) AS total_comment_length,
      COUNT(DISTINCT c.creator_person_id) AS distinct_commenters
    FROM comment c
    GROUP BY c.parent_post_id
  ),
  forum_tag_stats AS (
    SELECT
      f.id AS forum_id,
      f.title AS forum_title,
      t.id AS tag_id,
      t.name AS tag_name,
      COUNT(DISTINCT p.id) AS post_count,
      AVG(p.length) AS avg_post_length,
      SUM(p.length) AS total_post_length,
      COALESCE(SUM(pl.like_count), 0) AS total_like_count,
      COALESCE(SUM(pl.distinct_likers), 0) AS total_distinct_likers,
      COALESCE(SUM(pc.comment_count), 0) AS total_comment_count,
      CASE
        WHEN COALESCE(SUM(pc.comment_count), 0) > 0 THEN CAST(SUM(pc.total_comment_length) AS DOUBLE) / SUM(pc.comment_count)
        ELSE NULL
      END AS avg_comment_length,
      COALESCE(SUM(pc.distinct_commenters), 0) AS total_distinct_commenters
    FROM post p
    JOIN forum f ON p.container_forum_id = f.id
    JOIN post_has_tag_tag pt ON pt.post_id = p.id
    JOIN tag t ON pt.tag_id = t.id
    LEFT JOIN post_likes pl ON pl.post_id = p.id
    LEFT JOIN post_comments pc ON pc.post_id = p.id
    GROUP BY f.id, f.title, t.id, t.name
  )
SELECT
  forum_id,
  forum_title,
  tag_id,
  tag_name,
  post_count,
  avg_post_length,
  total_post_length,
  total_like_count,
  total_distinct_likers,
  total_comment_count,
  avg_comment_length,
  total_distinct_commenters
FROM forum_tag_stats
ORDER BY total_post_length DESC
LIMIT 10
