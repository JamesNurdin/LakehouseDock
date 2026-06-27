WITH forum_posts AS (
    SELECT f.id AS forum_id,
           COUNT(DISTINCT p.id) AS post_count,
           AVG(p.length) AS avg_post_length
    FROM forum f
    JOIN post p
      ON p.container_forum_id = f.id
    GROUP BY f.id
),
forum_comments AS (
    SELECT f.id AS forum_id,
           COUNT(DISTINCT c.id) AS comment_count
    FROM forum f
    JOIN post p
      ON p.container_forum_id = f.id
    JOIN comment c
      ON c.parent_post_id = p.id
    GROUP BY f.id
),
forum_post_likes AS (
    SELECT f.id AS forum_id,
           COUNT(pl.person_id) AS post_like_count
    FROM forum f
    JOIN post p
      ON p.container_forum_id = f.id
    JOIN person_likes_post pl
      ON pl.post_id = p.id
    GROUP BY f.id
),
forum_comment_likes AS (
    SELECT f.id AS forum_id,
           COUNT(cl.person_id) AS comment_like_count
    FROM forum f
    JOIN post p
      ON p.container_forum_id = f.id
    JOIN comment c
      ON c.parent_post_id = p.id
    JOIN person_likes_comment cl
      ON cl.comment_id = c.id
    GROUP BY f.id
),
forum_members AS (
    SELECT f.id AS forum_id,
           COUNT(DISTINCT fm.person_id) AS member_count
    FROM forum f
    JOIN forum_has_member_person fm
      ON fm.forum_id = f.id
    GROUP BY f.id
),
forum_tags AS (
    SELECT f.id AS forum_id,
           COUNT(DISTINCT ft.tag_id) AS tag_count
    FROM forum f
    JOIN forum_has_tag_tag ft
      ON ft.forum_id = f.id
    GROUP BY f.id
)
SELECT f.id AS forum_id,
       f.title,
       COALESCE(fp.post_count, 0) AS post_count,
       COALESCE(fc.comment_count, 0) AS comment_count,
       COALESCE(fpl.post_like_count, 0) AS post_like_count,
       COALESCE(fcl.comment_like_count, 0) AS comment_like_count,
       COALESCE(fm.member_count, 0) AS member_count,
       COALESCE(ft.tag_count, 0) AS tag_count,
       COALESCE(fp.avg_post_length, 0) AS avg_post_length,
       (COALESCE(fpl.post_like_count, 0) + COALESCE(fcl.comment_like_count, 0)) AS total_like_count
FROM forum f
LEFT JOIN forum_posts fp
  ON fp.forum_id = f.id
LEFT JOIN forum_comments fc
  ON fc.forum_id = f.id
LEFT JOIN forum_post_likes fpl
  ON fpl.forum_id = f.id
LEFT JOIN forum_comment_likes fcl
  ON fcl.forum_id = f.id
LEFT JOIN forum_members fm
  ON fm.forum_id = f.id
LEFT JOIN forum_tags ft
  ON ft.forum_id = f.id
ORDER BY total_like_count DESC
LIMIT 10
