WITH member_counts AS (
    SELECT forum_id,
           COUNT(DISTINCT person_id) AS member_count
    FROM forum_has_member_person
    GROUP BY forum_id
),
post_stats AS (
    SELECT container_forum_id AS forum_id,
           COUNT(*) AS post_count,
           SUM(length) AS total_post_length,
           AVG(length) AS avg_post_length
    FROM post
    WHERE creation_date >= '2015-01-01'
    GROUP BY container_forum_id
),
comment_counts AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(*) AS comment_count
    FROM comment c
    JOIN post p
      ON c.parent_post_id = p.id
    WHERE c.creation_date >= '2015-01-01'
    GROUP BY p.container_forum_id
),
like_counts AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(*) AS like_count
    FROM person_likes_post plp
    JOIN post p
      ON plp.post_id = p.id
    WHERE plp.creation_date >= '2015-01-01'
    GROUP BY p.container_forum_id
)
SELECT f.id AS forum_id,
       f.title,
       f.creation_date AS forum_creation_date,
       p_mod.first_name AS moderator_first_name,
       p_mod.last_name AS moderator_last_name,
       COALESCE(m.member_count, 0) AS member_count,
       COALESCE(pst.post_count, 0) AS post_count,
       COALESCE(pst.total_post_length, 0) AS total_post_length,
       COALESCE(pst.avg_post_length, 0) AS avg_post_length,
       COALESCE(cc.comment_count, 0) AS comment_count,
       COALESCE(lc.like_count, 0) AS like_count
FROM forum f
LEFT JOIN person p_mod
  ON f.moderator_person_id = p_mod.id
LEFT JOIN member_counts m
  ON m.forum_id = f.id
LEFT JOIN post_stats pst
  ON pst.forum_id = f.id
LEFT JOIN comment_counts cc
  ON cc.forum_id = f.id
LEFT JOIN like_counts lc
  ON lc.forum_id = f.id
WHERE f.creation_date >= '2015-01-01'
ORDER BY member_count DESC, post_count DESC
LIMIT 100
