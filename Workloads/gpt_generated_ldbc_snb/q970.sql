WITH member_counts AS (
    SELECT fm.forum_id, COUNT(DISTINCT fm.person_id) AS member_count
    FROM forum_has_member_person fm
    GROUP BY fm.forum_id
),
post_stats AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(*) AS post_count,
           AVG(p.length) AS avg_post_length
    FROM post p
    GROUP BY p.container_forum_id
),
post_like_counts AS (
    SELECT p.container_forum_id AS forum_id,
           SUM(like_cnt) AS total_post_likes
    FROM post p
    LEFT JOIN (
        SELECT post_id, COUNT(*) AS like_cnt
        FROM person_likes_post
        GROUP BY post_id
    ) plp
      ON plp.post_id = p.id
    GROUP BY p.container_forum_id
),
comment_stats AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(c.id) AS comment_count,
           AVG(c.length) AS avg_comment_length
    FROM comment c
    LEFT JOIN post p
      ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
),
comment_like_counts AS (
    SELECT p.container_forum_id AS forum_id,
           SUM(lc.like_cnt) AS total_comment_likes
    FROM comment c
    LEFT JOIN post p
      ON c.parent_post_id = p.id
    LEFT JOIN (
        SELECT comment_id, COUNT(*) AS like_cnt
        FROM person_likes_comment
        GROUP BY comment_id
    ) lc
      ON lc.comment_id = c.id
    GROUP BY p.container_forum_id
)
SELECT
    f.id AS forum_id,
    f.title,
    f.creation_date,
    COALESCE(mc.member_count, 0) AS member_count,
    COALESCE(ps.post_count, 0) AS post_count,
    ps.avg_post_length,
    cs.comment_count,
    cs.avg_comment_length,
    COALESCE(plc.total_post_likes, 0) AS total_post_likes,
    COALESCE(clc.total_comment_likes, 0) AS total_comment_likes,
    CASE WHEN COALESCE(ps.post_count, 0) = 0 THEN NULL
         ELSE COALESCE(plc.total_post_likes, 0) / ps.post_count END AS avg_likes_per_post,
    CASE WHEN COALESCE(cs.comment_count, 0) = 0 THEN NULL
         ELSE COALESCE(clc.total_comment_likes, 0) / cs.comment_count END AS avg_likes_per_comment
FROM forum f
LEFT JOIN member_counts mc
  ON mc.forum_id = f.id
LEFT JOIN post_stats ps
  ON ps.forum_id = f.id
LEFT JOIN post_like_counts plc
  ON plc.forum_id = f.id
LEFT JOIN comment_stats cs
  ON cs.forum_id = f.id
LEFT JOIN comment_like_counts clc
  ON clc.forum_id = f.id
ORDER BY post_count DESC
LIMIT 10
