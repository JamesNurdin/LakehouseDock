/*
  Analytical query: forum‑level activity summary
  - Member count per forum
  - Posts and post length statistics
  - Comment statistics (count, avg length)
  - Likes on posts and comments
  - Derived average likes per post / comment
  - Moderator name
  Ordered by the most populated forums.
*/
WITH
  members AS (
    SELECT fhm.forum_id,
           COUNT(DISTINCT fhm.person_id) AS member_count
    FROM forum_has_member_person fhm
    GROUP BY fhm.forum_id
  ),
  posts AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(DISTINCT p.id) AS post_count,
           SUM(p.length) AS total_post_length,
           AVG(p.length) AS avg_post_length
    FROM post p
    GROUP BY p.container_forum_id
  ),
  comments AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(DISTINCT c.id) AS comment_count,
           AVG(c.length) AS avg_comment_length
    FROM comment c
    JOIN post p ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
  ),
  post_likes AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(*) AS post_like_count
    FROM person_likes_post plp
    JOIN post p ON plp.post_id = p.id
    GROUP BY p.container_forum_id
  ),
  comment_likes AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(*) AS comment_like_count
    FROM person_likes_comment plc
    JOIN comment c ON plc.comment_id = c.id
    JOIN post p ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
  ),
  moderators AS (
    SELECT f.id AS forum_id,
           per.first_name AS moderator_first_name,
           per.last_name  AS moderator_last_name
    FROM forum f
    JOIN person per ON f.moderator_person_id = per.id
  )
SELECT f.id AS forum_id,
       f.title AS forum_title,
       modr.moderator_first_name,
       modr.moderator_last_name,
       COALESCE(mem.member_count, 0)          AS member_count,
       COALESCE(pst.post_count, 0)           AS post_count,
       COALESCE(pst.total_post_length, 0)    AS total_post_length,
       COALESCE(pst.avg_post_length, 0)      AS avg_post_length,
       COALESCE(cmt.comment_count, 0)        AS comment_count,
       COALESCE(cmt.avg_comment_length, 0)   AS avg_comment_length,
       COALESCE(pl.post_like_count, 0)       AS post_like_count,
       COALESCE(cl.comment_like_count, 0)    AS comment_like_count,
       (COALESCE(pl.post_like_count, 0) / NULLIF(COALESCE(pst.post_count, 0), 0))   AS avg_likes_per_post,
       (COALESCE(cl.comment_like_count, 0) / NULLIF(COALESCE(cmt.comment_count, 0), 0)) AS avg_likes_per_comment
FROM forum f
LEFT JOIN moderators   modr ON f.id = modr.forum_id
LEFT JOIN members      mem  ON f.id = mem.forum_id
LEFT JOIN posts        pst  ON f.id = pst.forum_id
LEFT JOIN comments     cmt  ON f.id = cmt.forum_id
LEFT JOIN post_likes   pl   ON f.id = pl.forum_id
LEFT JOIN comment_likes cl  ON f.id = cl.forum_id
ORDER BY member_count DESC
LIMIT 100
