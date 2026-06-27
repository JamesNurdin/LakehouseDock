WITH forum_base AS (
  SELECT f.id AS forum_id,
         f.title,
         f.moderator_person_id
  FROM forum f
),
moderator AS (
  SELECT p.id AS person_id,
         p.first_name,
         p.last_name
  FROM person p
),
forum_moderator AS (
  SELECT fb.forum_id,
         fb.title,
         m.first_name AS moderator_first_name,
         m.last_name  AS moderator_last_name
  FROM forum_base fb
  LEFT JOIN moderator m
    ON fb.moderator_person_id = m.person_id
),
post_stats AS (
  SELECT p.container_forum_id AS forum_id,
         COUNT(*)               AS post_count,
         AVG(p.length)          AS avg_post_length
  FROM post p
  GROUP BY p.container_forum_id
),
comment_stats AS (
  SELECT po.container_forum_id AS forum_id,
         COUNT(*)               AS comment_count
  FROM comment c
  JOIN post po
    ON c.parent_post_id = po.id
  GROUP BY po.container_forum_id
),
post_like_stats AS (
  SELECT po.container_forum_id AS forum_id,
         COUNT(*)               AS post_like_count
  FROM person_likes_post plp
  JOIN post po
    ON plp.post_id = po.id
  GROUP BY po.container_forum_id
),
comment_like_stats AS (
  SELECT po.container_forum_id AS forum_id,
         COUNT(*)               AS comment_like_count
  FROM person_likes_comment plc
  JOIN comment c
    ON plc.comment_id = c.id
  JOIN post po
    ON c.parent_post_id = po.id
  GROUP BY po.container_forum_id
),
post_tag_stats AS (
  SELECT po.container_forum_id AS forum_id,
         COUNT(DISTINCT pht.tag_id) AS post_tag_count
  FROM post_has_tag_tag pht
  JOIN post po
    ON pht.post_id = po.id
  GROUP BY po.container_forum_id
),
comment_tag_stats AS (
  SELECT po.container_forum_id AS forum_id,
         COUNT(DISTINCT cht.tag_id) AS comment_tag_count
  FROM comment_has_tag_tag cht
  JOIN comment c
    ON cht.comment_id = c.id
  JOIN post po
    ON c.parent_post_id = po.id
  GROUP BY po.container_forum_id
),
member_stats AS (
  SELECT fm.forum_id,
         COUNT(DISTINCT fm.person_id) AS member_count
  FROM forum_has_member_person fm
  GROUP BY fm.forum_id
)
SELECT fm.forum_id,
       fm.title,
       fm.moderator_first_name,
       fm.moderator_last_name,
       COALESCE(ms.member_count, 0)               AS member_count,
       COALESCE(ps.post_count, 0)                 AS post_count,
       COALESCE(cs.comment_count, 0)              AS comment_count,
       ps.avg_post_length,
       CASE WHEN COALESCE(ps.post_count, 0) = 0 THEN NULL
            ELSE cs.comment_count / ps.post_count END AS avg_comments_per_post,
       CASE WHEN COALESCE(ps.post_count, 0) = 0 THEN NULL
            ELSE plps.post_like_count / ps.post_count END AS avg_likes_per_post,
       CASE WHEN COALESCE(cs.comment_count, 0) = 0 THEN NULL
            ELSE clss.comment_like_count / cs.comment_count END AS avg_likes_per_comment,
       COALESCE(pts.post_tag_count, 0)            AS post_tag_count,
       COALESCE(cts.comment_tag_count, 0)         AS comment_tag_count
FROM forum_moderator fm
LEFT JOIN member_stats       ms   ON fm.forum_id = ms.forum_id
LEFT JOIN post_stats         ps   ON fm.forum_id = ps.forum_id
LEFT JOIN comment_stats      cs   ON fm.forum_id = cs.forum_id
LEFT JOIN post_like_stats    plps ON fm.forum_id = plps.forum_id
LEFT JOIN comment_like_stats clss ON fm.forum_id = clss.forum_id
LEFT JOIN post_tag_stats     pts  ON fm.forum_id = pts.forum_id
LEFT JOIN comment_tag_stats  cts  ON fm.forum_id = cts.forum_id
ORDER BY fm.forum_id
LIMIT 100
