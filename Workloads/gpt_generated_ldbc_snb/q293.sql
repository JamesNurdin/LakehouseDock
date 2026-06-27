WITH forum_mod AS (
    SELECT f.id AS forum_id,
           f.title,
           p.first_name AS moderator_first_name,
           p.last_name AS moderator_last_name
    FROM forum f
    JOIN person p
      ON f.moderator_person_id = p.id
),

post_counts AS (
    SELECT f.id AS forum_id,
           COUNT(p.id) AS total_posts,
           AVG(p.length) AS avg_post_length
    FROM forum f
    JOIN post p
      ON p.container_forum_id = f.id
    GROUP BY f.id
),

post_tag_counts AS (
    SELECT f.id AS forum_id,
           COUNT(DISTINCT pt.tag_id) AS distinct_post_tags
    FROM forum f
    JOIN post p
      ON p.container_forum_id = f.id
    LEFT JOIN post_has_tag_tag pt
      ON pt.post_id = p.id
    GROUP BY f.id
),

comment_stats AS (
    SELECT f.id AS forum_id,
           COUNT(c.id) AS total_comments,
           AVG(c.length) AS avg_comment_length
    FROM forum f
    JOIN post p
      ON p.container_forum_id = f.id
    JOIN comment c
      ON c.parent_post_id = p.id
    GROUP BY f.id
),

member_stats AS (
    SELECT f.id AS forum_id,
           COUNT(DISTINCT fm.person_id) AS total_members
    FROM forum f
    JOIN forum_has_member_person fm
      ON fm.forum_id = f.id
    GROUP BY f.id
),

forum_tag_stats AS (
    SELECT f.id AS forum_id,
           COUNT(DISTINCT ft.tag_id) AS distinct_forum_tags
    FROM forum f
    JOIN forum_has_tag_tag ft
      ON ft.forum_id = f.id
    GROUP BY f.id
)

SELECT fm.forum_id,
       fm.title,
       fm.moderator_first_name,
       fm.moderator_last_name,
       COALESCE(pc.total_posts, 0) AS total_posts,
       COALESCE(cs.total_comments, 0) AS total_comments,
       pc.avg_post_length,
       cs.avg_comment_length,
       COALESCE(ptc.distinct_post_tags, 0) AS distinct_post_tags,
       COALESCE(fts.distinct_forum_tags, 0) AS distinct_forum_tags,
       COALESCE(ms.total_members, 0) AS total_members
FROM forum_mod fm
LEFT JOIN post_counts pc
  ON pc.forum_id = fm.forum_id
LEFT JOIN post_tag_counts ptc
  ON ptc.forum_id = fm.forum_id
LEFT JOIN comment_stats cs
  ON cs.forum_id = fm.forum_id
LEFT JOIN member_stats ms
  ON ms.forum_id = fm.forum_id
LEFT JOIN forum_tag_stats fts
  ON fts.forum_id = fm.forum_id
ORDER BY fm.forum_id
