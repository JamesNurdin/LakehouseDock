WITH forum_info AS (
  SELECT f.id AS forum_id,
         f.title AS forum_title,
         mod.first_name AS moderator_first_name,
         mod.last_name AS moderator_last_name
  FROM forum f
  LEFT JOIN person mod
    ON f.moderator_person_id = mod.id
),
forum_members AS (
  SELECT fm.forum_id,
         COUNT(DISTINCT fm.person_id) AS member_count
  FROM forum_has_member_person fm
  GROUP BY fm.forum_id
),
forum_posts_metrics AS (
  SELECT p.container_forum_id AS forum_id,
         COUNT(*) AS post_count,
         AVG(p.length) AS avg_post_length
  FROM post p
  GROUP BY p.container_forum_id
),
forum_post_tags AS (
  SELECT p.container_forum_id AS forum_id,
         COUNT(DISTINCT pt.tag_id) AS distinct_post_tag_count
  FROM post p
  LEFT JOIN post_has_tag_tag pt
    ON pt.post_id = p.id
  GROUP BY p.container_forum_id
),
forum_comments_metrics AS (
  SELECT p.container_forum_id AS forum_id,
         COUNT(*) AS comment_count,
         AVG(c.length) AS avg_comment_length
  FROM comment c
  JOIN post p
    ON c.parent_post_id = p.id
  GROUP BY p.container_forum_id
),
forum_comment_tags AS (
  SELECT p.container_forum_id AS forum_id,
         COUNT(DISTINCT ct.tag_id) AS distinct_comment_tag_count
  FROM comment c
  JOIN post p
    ON c.parent_post_id = p.id
  LEFT JOIN comment_has_tag_tag ct
    ON ct.comment_id = c.id
  GROUP BY p.container_forum_id
),
forum_post_likes AS (
  SELECT p.container_forum_id AS forum_id,
         COUNT(*) AS post_like_count
  FROM person_likes_post pl
  JOIN post p
    ON pl.post_id = p.id
  GROUP BY p.container_forum_id
),
forum_comment_likes AS (
  SELECT p.container_forum_id AS forum_id,
         COUNT(*) AS comment_like_count
  FROM person_likes_comment cl
  JOIN comment c
    ON cl.comment_id = c.id
  JOIN post p
    ON c.parent_post_id = p.id
  GROUP BY p.container_forum_id
)
SELECT
  fi.forum_id,
  fi.forum_title,
  fi.moderator_first_name,
  fi.moderator_last_name,
  COALESCE(fm.member_count, 0) AS member_count,
  COALESCE(fp.post_count, 0) AS post_count,
  COALESCE(fp.avg_post_length, 0) AS avg_post_length,
  COALESCE(fc.comment_count, 0) AS comment_count,
  COALESCE(fc.avg_comment_length, 0) AS avg_comment_length,
  COALESCE(fpl.post_like_count, 0) AS post_like_count,
  COALESCE(fcl.comment_like_count, 0) AS comment_like_count,
  COALESCE(fpt.distinct_post_tag_count, 0) AS distinct_post_tag_count,
  COALESCE(fct.distinct_comment_tag_count, 0) AS distinct_comment_tag_count
FROM forum_info fi
LEFT JOIN forum_members fm
  ON fm.forum_id = fi.forum_id
LEFT JOIN forum_posts_metrics fp
  ON fp.forum_id = fi.forum_id
LEFT JOIN forum_post_tags fpt
  ON fpt.forum_id = fi.forum_id
LEFT JOIN forum_comments_metrics fc
  ON fc.forum_id = fi.forum_id
LEFT JOIN forum_comment_tags fct
  ON fct.forum_id = fi.forum_id
LEFT JOIN forum_post_likes fpl
  ON fpl.forum_id = fi.forum_id
LEFT JOIN forum_comment_likes fcl
  ON fcl.forum_id = fi.forum_id
ORDER BY member_count DESC
LIMIT 20
