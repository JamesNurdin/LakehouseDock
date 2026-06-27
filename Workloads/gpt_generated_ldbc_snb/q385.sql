WITH forum_base AS (
    SELECT f.id,
           f.title,
           f.creation_date
    FROM forum f
),

post_metrics AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(DISTINCT p.id) AS num_posts,
           AVG(p.length) AS avg_post_length
    FROM post p
    GROUP BY p.container_forum_id
),

comment_metrics AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(DISTINCT c.id) AS num_comments,
           AVG(c.length) AS avg_comment_length
    FROM comment c
    JOIN post p
      ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
),

member_metrics AS (
    SELECT fm.forum_id,
           COUNT(DISTINCT fm.person_id) AS num_members
    FROM forum_has_member_person fm
    GROUP BY fm.forum_id
),

tag_metrics AS (
    SELECT ft.forum_id,
           COUNT(DISTINCT ft.tag_id) AS num_tags
    FROM forum_has_tag_tag ft
    GROUP BY ft.forum_id
),

post_like_metrics AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(plp.person_id) AS total_post_likes,
           COUNT(DISTINCT plp.person_id) AS distinct_post_likers
    FROM person_likes_post plp
    JOIN post p
      ON plp.post_id = p.id
    GROUP BY p.container_forum_id
),

comment_like_metrics AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(plc.person_id) AS total_comment_likes,
           COUNT(DISTINCT plc.person_id) AS distinct_comment_likers
    FROM person_likes_comment plc
    JOIN comment c
      ON plc.comment_id = c.id
    JOIN post p
      ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
)

SELECT fb.id AS forum_id,
       fb.title,
       fb.creation_date,
       COALESCE(pm.num_posts, 0) AS num_posts,
       COALESCE(cm.num_comments, 0) AS num_comments,
       COALESCE(mm.num_members, 0) AS num_members,
       COALESCE(tm.num_tags, 0) AS num_tags,
       COALESCE(pm.avg_post_length, 0) AS avg_post_length,
       COALESCE(cm.avg_comment_length, 0) AS avg_comment_length,
       COALESCE(plm.total_post_likes, 0) AS total_post_likes,
       COALESCE(plm.distinct_post_likers, 0) AS distinct_post_likers,
       COALESCE(clm.total_comment_likes, 0) AS total_comment_likes,
       COALESCE(clm.distinct_comment_likers, 0) AS distinct_comment_likers
FROM forum_base fb
LEFT JOIN post_metrics pm
  ON fb.id = pm.forum_id
LEFT JOIN comment_metrics cm
  ON fb.id = cm.forum_id
LEFT JOIN member_metrics mm
  ON fb.id = mm.forum_id
LEFT JOIN tag_metrics tm
  ON fb.id = tm.forum_id
LEFT JOIN post_like_metrics plm
  ON fb.id = plm.forum_id
LEFT JOIN comment_like_metrics clm
  ON fb.id = clm.forum_id
ORDER BY num_posts DESC
LIMIT 10
