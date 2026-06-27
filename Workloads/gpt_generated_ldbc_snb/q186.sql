WITH forum_members AS (
    SELECT f.id AS forum_id,
           COUNT(DISTINCT fm.person_id) AS member_count
    FROM forum AS f
    JOIN forum_has_member_person AS fm
      ON fm.forum_id = f.id
    GROUP BY f.id
),
forum_posts AS (
    SELECT f.id AS forum_id,
           COUNT(DISTINCT po.id) AS post_count
    FROM forum AS f
    JOIN post AS po
      ON po.container_forum_id = f.id
    GROUP BY f.id
),
forum_comments AS (
    SELECT f.id AS forum_id,
           COUNT(DISTINCT c.id) AS comment_count,
           AVG(c.length) AS avg_comment_length
    FROM forum AS f
    JOIN post AS po
      ON po.container_forum_id = f.id
    JOIN comment AS c
      ON c.parent_post_id = po.id
    GROUP BY f.id
),
forum_comment_likes AS (
    SELECT f.id AS forum_id,
           COUNT(plc.person_id) AS comment_like_count
    FROM forum AS f
    JOIN post AS po
      ON po.container_forum_id = f.id
    JOIN comment AS c
      ON c.parent_post_id = po.id
    JOIN person_likes_comment AS plc
      ON plc.comment_id = c.id
    GROUP BY f.id
)
SELECT f.id AS forum_id,
       f.title,
       moderator.first_name AS moderator_first_name,
       moderator.last_name AS moderator_last_name,
       fm.member_count,
       fp.post_count,
       fc.comment_count,
       fc.avg_comment_length,
       fcl.comment_like_count
FROM forum AS f
LEFT JOIN forum_members AS fm
  ON fm.forum_id = f.id
LEFT JOIN forum_posts AS fp
  ON fp.forum_id = f.id
LEFT JOIN forum_comments AS fc
  ON fc.forum_id = f.id
LEFT JOIN forum_comment_likes AS fcl
  ON fcl.forum_id = f.id
LEFT JOIN person AS moderator
  ON moderator.id = f.moderator_person_id
ORDER BY f.id
