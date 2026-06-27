SELECT
    f.id AS forum_id,
    f.title,
    mod.first_name || ' ' || mod.last_name AS moderator_name,
    mod.gender AS moderator_gender,
    COALESCE(pm.post_count, 0) AS post_count,
    COALESCE(pm.avg_post_length, 0) AS avg_post_length,
    COALESCE(cm.comment_count, 0) AS comment_count,
    COALESCE(cm.avg_comment_length, 0) AS avg_comment_length,
    COALESCE(mm.member_count, 0) AS member_count,
    COALESCE(plm.post_like_count, 0) AS post_like_count,
    COALESCE(clm.comment_like_count, 0) AS comment_like_count
FROM forum f
JOIN person mod
  ON f.moderator_person_id = mod.id
LEFT JOIN (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(*) AS post_count,
        AVG(p.length) AS avg_post_length
    FROM post p
    GROUP BY p.container_forum_id
) pm
  ON f.id = pm.forum_id
LEFT JOIN (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(c.id) AS comment_count,
        AVG(c.length) AS avg_comment_length
    FROM comment c
    JOIN post p
      ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
) cm
  ON f.id = cm.forum_id
LEFT JOIN (
    SELECT
        fhm.forum_id,
        COUNT(DISTINCT fhm.person_id) AS member_count
    FROM forum_has_member_person fhm
    GROUP BY fhm.forum_id
) mm
  ON f.id = mm.forum_id
LEFT JOIN (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(pl.person_id) AS post_like_count
    FROM person_likes_post pl
    JOIN post p
      ON pl.post_id = p.id
    GROUP BY p.container_forum_id
) plm
  ON f.id = plm.forum_id
LEFT JOIN (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(cl.person_id) AS comment_like_count
    FROM person_likes_comment cl
    JOIN comment c
      ON cl.comment_id = c.id
    JOIN post p
      ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
) clm
  ON f.id = clm.forum_id
ORDER BY f.id
