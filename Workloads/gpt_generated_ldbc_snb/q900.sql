/*
  Analytical query for the LDBC SNB BI dataset (sf0003) using Trino.
  It returns the top 10 forums ordered by the number of posts, together with:
    • forum title and moderator name
    • total posts and average post length
    • total comments and average comment length
    • number of distinct forum members
    • total likes on posts and on comments within the forum
*/
WITH forum_mod AS (
    SELECT f.id AS forum_id,
           f.title,
           p.first_name,
           p.last_name
    FROM forum f
    LEFT JOIN person p
        ON f.moderator_person_id = p.id
),
post_stats AS (
    SELECT container_forum_id AS forum_id,
           COUNT(id) AS post_count,
           AVG(length) AS avg_post_length
    FROM post
    GROUP BY container_forum_id
),
comment_stats AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(c.id) AS comment_count,
           AVG(c.length) AS avg_comment_length
    FROM comment c
    JOIN post p
        ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
),
member_stats AS (
    SELECT forum_id,
           COUNT(DISTINCT person_id) AS member_count
    FROM forum_has_member_person
    GROUP BY forum_id
),
post_like_stats AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(pl.person_id) AS post_like_count
    FROM post p
    JOIN person_likes_post pl
        ON pl.post_id = p.id
    GROUP BY p.container_forum_id
),
comment_like_stats AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(cl.person_id) AS comment_like_count
    FROM comment c
    JOIN post p
        ON c.parent_post_id = p.id
    JOIN person_likes_comment cl
        ON cl.comment_id = c.id
    GROUP BY p.container_forum_id
)
SELECT fm.forum_id,
       fm.title,
       fm.first_name AS moderator_first_name,
       fm.last_name  AS moderator_last_name,
       COALESCE(ps.post_count, 0)          AS post_count,
       COALESCE(ps.avg_post_length, 0)    AS avg_post_length,
       COALESCE(cs.comment_count, 0)      AS comment_count,
       COALESCE(cs.avg_comment_length, 0) AS avg_comment_length,
       COALESCE(ms.member_count, 0)       AS member_count,
       COALESCE(pls.post_like_count, 0)   AS post_like_count,
       COALESCE(cls.comment_like_count, 0) AS comment_like_count
FROM forum_mod fm
LEFT JOIN post_stats          ps  ON fm.forum_id = ps.forum_id
LEFT JOIN comment_stats       cs  ON fm.forum_id = cs.forum_id
LEFT JOIN member_stats        ms  ON fm.forum_id = ms.forum_id
LEFT JOIN post_like_stats     pls ON fm.forum_id = pls.forum_id
LEFT JOIN comment_like_stats  cls ON fm.forum_id = cls.forum_id
ORDER BY post_count DESC
LIMIT 10
