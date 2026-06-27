WITH forum_info AS (
    SELECT f.id AS forum_id,
           f.title AS title,
           p_mod.first_name AS moderator_first_name,
           p_mod.last_name AS moderator_last_name
    FROM forum AS f
    JOIN person AS p_mod
      ON f.moderator_person_id = p_mod.id
),
member_counts AS (
    SELECT f.id AS forum_id,
           COUNT(DISTINCT fmp.person_id) AS member_count
    FROM forum_has_member_person AS fmp
    JOIN forum AS f
      ON fmp.forum_id = f.id
    GROUP BY f.id
),
tag_counts AS (
    SELECT f.id AS forum_id,
           COUNT(DISTINCT ftt.tag_id) AS tag_count
    FROM forum_has_tag_tag AS ftt
    JOIN forum AS f
      ON ftt.forum_id = f.id
    GROUP BY f.id
),
post_stats AS (
    SELECT f.id AS forum_id,
           COUNT(DISTINCT p.id) AS post_count,
           AVG(p.length) AS avg_post_length
    FROM post AS p
    JOIN forum AS f
      ON p.container_forum_id = f.id
    GROUP BY f.id
),
comment_stats AS (
    SELECT f.id AS forum_id,
           COUNT(DISTINCT c.id) AS comment_count,
           AVG(c.length) AS avg_comment_length
    FROM comment AS c
    JOIN post AS p
      ON c.parent_post_id = p.id
    JOIN forum AS f
      ON p.container_forum_id = f.id
    GROUP BY f.id
)
SELECT fi.forum_id,
       fi.title,
       fi.moderator_first_name,
       fi.moderator_last_name,
       COALESCE(mc.member_count, 0) AS member_count,
       COALESCE(tc.tag_count, 0) AS tag_count,
       COALESCE(ps.post_count, 0) AS post_count,
       ps.avg_post_length,
       COALESCE(cs.comment_count, 0) AS comment_count,
       cs.avg_comment_length,
       (COALESCE(cs.comment_count, 0) * 1.0) / NULLIF(COALESCE(ps.post_count, 0), 0) AS avg_comments_per_post
FROM forum_info AS fi
LEFT JOIN member_counts AS mc
  ON fi.forum_id = mc.forum_id
LEFT JOIN tag_counts AS tc
  ON fi.forum_id = tc.forum_id
LEFT JOIN post_stats AS ps
  ON fi.forum_id = ps.forum_id
LEFT JOIN comment_stats AS cs
  ON fi.forum_id = cs.forum_id
ORDER BY fi.forum_id
