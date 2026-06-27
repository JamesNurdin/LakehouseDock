WITH
  post_base AS (
    SELECT
      f.id AS forum_id,
      COUNT(p.id) AS num_posts,
      AVG(p.length) AS avg_post_length,
      COUNT(DISTINCT p.creator_person_id) AS distinct_post_creators
    FROM forum f
    LEFT JOIN post p
      ON p.container_forum_id = f.id
    GROUP BY f.id
  ),
  post_likes AS (
    SELECT
      f.id AS forum_id,
      COUNT(plp.person_id) AS total_post_likes
    FROM forum f
    LEFT JOIN post p
      ON p.container_forum_id = f.id
    LEFT JOIN person_likes_post plp
      ON plp.post_id = p.id
    GROUP BY f.id
  ),
  comment_base AS (
    SELECT
      f.id AS forum_id,
      COUNT(c.id) AS num_comments,
      AVG(c.length) AS avg_comment_length,
      COUNT(DISTINCT c.creator_person_id) AS distinct_comment_creators
    FROM forum f
    LEFT JOIN post p
      ON p.container_forum_id = f.id
    LEFT JOIN comment c
      ON c.parent_post_id = p.id
    GROUP BY f.id
  ),
  comment_likes AS (
    SELECT
      f.id AS forum_id,
      COUNT(plc.person_id) AS total_comment_likes
    FROM forum f
    LEFT JOIN post p
      ON p.container_forum_id = f.id
    LEFT JOIN comment c
      ON c.parent_post_id = p.id
    LEFT JOIN person_likes_comment plc
      ON plc.comment_id = c.id
    GROUP BY f.id
  ),
  participants AS (
    SELECT
      forum_id,
      COUNT(DISTINCT person_id) AS distinct_participants
    FROM (
      SELECT f.id AS forum_id, p.creator_person_id AS person_id
      FROM forum f
      LEFT JOIN post p
        ON p.container_forum_id = f.id
      UNION ALL
      SELECT f.id AS forum_id, c.creator_person_id AS person_id
      FROM forum f
      LEFT JOIN post p
        ON p.container_forum_id = f.id
      LEFT JOIN comment c
        ON c.parent_post_id = p.id
    ) t
    WHERE person_id IS NOT NULL
    GROUP BY forum_id
  ),
  tag_counts AS (
    SELECT f.id AS forum_id, pt.tag_id
    FROM forum f
    JOIN post p
      ON p.container_forum_id = f.id
    JOIN post_has_tag_tag pt
      ON pt.post_id = p.id
    UNION ALL
    SELECT f.id AS forum_id, ct.tag_id
    FROM forum f
    JOIN post p
      ON p.container_forum_id = f.id
    JOIN comment c
      ON c.parent_post_id = p.id
    JOIN comment_has_tag_tag ct
      ON ct.comment_id = c.id
  ),
  tag_agg AS (
    SELECT forum_id, tag_id, COUNT(*) AS usage
    FROM tag_counts
    GROUP BY forum_id, tag_id
  ),
  top_tags AS (
    SELECT
      forum_id,
      tag_id,
      usage,
      ROW_NUMBER() OVER (PARTITION BY forum_id ORDER BY usage DESC) AS rn
    FROM tag_agg
  )
SELECT
  f.id AS forum_id,
  f.title AS forum_title,
  COALESCE(pb.num_posts, 0) AS num_posts,
  COALESCE(cb.num_comments, 0) AS num_comments,
  pb.avg_post_length,
  cb.avg_comment_length,
  COALESCE(pl.total_post_likes, 0) AS total_post_likes,
  COALESCE(cl.total_comment_likes, 0) AS total_comment_likes,
  COALESCE(par.distinct_participants, 0) AS distinct_participants,
  tt.tag_id AS top_tag_id,
  tt.usage AS top_tag_usage
FROM forum f
LEFT JOIN post_base pb
  ON pb.forum_id = f.id
LEFT JOIN post_likes pl
  ON pl.forum_id = f.id
LEFT JOIN comment_base cb
  ON cb.forum_id = f.id
LEFT JOIN comment_likes cl
  ON cl.forum_id = f.id
LEFT JOIN participants par
  ON par.forum_id = f.id
LEFT JOIN top_tags tt
  ON tt.forum_id = f.id AND tt.rn = 1
ORDER BY num_posts DESC
LIMIT 10
