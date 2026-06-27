WITH forum_posts AS (
  SELECT f.id AS forum_id,
         COUNT(DISTINCT po.id) AS post_count
  FROM forum f
  LEFT JOIN post po ON po.container_forum_id = f.id
  GROUP BY f.id
),
forum_comments AS (
  SELECT f.id AS forum_id,
         COUNT(DISTINCT c.id) AS comment_count,
         AVG(c.length) AS avg_comment_length
  FROM forum f
  LEFT JOIN post po ON po.container_forum_id = f.id
  LEFT JOIN comment c ON c.parent_post_id = po.id
  GROUP BY f.id
),
forum_comment_likes AS (
  SELECT f.id AS forum_id,
         COUNT(DISTINCT plc.person_id) AS comment_like_count
  FROM forum f
  LEFT JOIN post po ON po.container_forum_id = f.id
  LEFT JOIN comment c ON c.parent_post_id = po.id
  LEFT JOIN person_likes_comment plc ON plc.comment_id = c.id
  GROUP BY f.id
),
forum_post_likes AS (
  SELECT f.id AS forum_id,
         COUNT(DISTINCT plp.person_id) AS post_like_count
  FROM forum f
  LEFT JOIN post po ON po.container_forum_id = f.id
  LEFT JOIN person_likes_post plp ON plp.post_id = po.id
  GROUP BY f.id
),
forum_members AS (
  SELECT f.id AS forum_id,
         COUNT(DISTINCT fmp.person_id) AS member_count
  FROM forum f
  LEFT JOIN forum_has_member_person fmp ON fmp.forum_id = f.id
  GROUP BY f.id
),
forum_tags AS (
  SELECT f.id AS forum_id,
         COUNT(DISTINCT ct.tag_id) AS distinct_tag_count
  FROM forum f
  LEFT JOIN post po ON po.container_forum_id = f.id
  LEFT JOIN comment c ON c.parent_post_id = po.id
  LEFT JOIN comment_has_tag_tag ct ON ct.comment_id = c.id
  GROUP BY f.id
)
SELECT f.id AS forum_id,
       f.title,
       p_mod.first_name AS moderator_first_name,
       p_mod.last_name  AS moderator_last_name,
       COALESCE(fp.post_count, 0)               AS post_count,
       COALESCE(fc.comment_count, 0)            AS comment_count,
       COALESCE(fc.avg_comment_length, 0)      AS avg_comment_length,
       COALESCE(fcl.comment_like_count, 0)     AS comment_like_count,
       COALESCE(fpl.post_like_count, 0)        AS post_like_count,
       COALESCE(fm.member_count, 0)            AS member_count,
       COALESCE(ft.distinct_tag_count, 0)      AS distinct_tag_count,
       CASE WHEN COALESCE(fc.comment_count, 0) > 0
            THEN CAST(COALESCE(fcl.comment_like_count, 0) AS DOUBLE) / COALESCE(fc.comment_count, 0)
            ELSE 0
       END AS avg_likes_per_comment,
       CASE WHEN COALESCE(fp.post_count, 0) > 0
            THEN CAST(COALESCE(fpl.post_like_count, 0) AS DOUBLE) / COALESCE(fp.post_count, 0)
            ELSE 0
       END AS avg_likes_per_post
FROM forum f
LEFT JOIN person p_mod ON p_mod.id = f.moderator_person_id
LEFT JOIN forum_posts fp          ON fp.forum_id = f.id
LEFT JOIN forum_comments fc      ON fc.forum_id = f.id
LEFT JOIN forum_comment_likes fcl ON fcl.forum_id = f.id
LEFT JOIN forum_post_likes fpl    ON fpl.forum_id = f.id
LEFT JOIN forum_members fm       ON fm.forum_id = f.id
LEFT JOIN forum_tags ft          ON ft.forum_id = f.id
ORDER BY post_count DESC
LIMIT 10
