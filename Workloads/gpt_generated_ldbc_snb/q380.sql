WITH comment_agg AS (
  SELECT
    t.id AS tag_id,
    t.name AS tag_name,
    COUNT(*) AS comment_count,
    AVG(c.length) AS avg_comment_length
  FROM comment_has_tag_tag ct
  JOIN comment c ON ct.comment_id = c.id
  JOIN tag t ON ct.tag_id = t.id
  GROUP BY t.id, t.name
),
post_agg AS (
  SELECT
    t.id AS tag_id,
    t.name AS tag_name,
    COUNT(*) AS post_count,
    AVG(p.length) AS avg_post_length
  FROM post_has_tag_tag pt
  JOIN post p ON pt.post_id = p.id
  JOIN tag t ON pt.tag_id = t.id
  GROUP BY t.id, t.name
),
creator_agg AS (
  SELECT
    tag_id,
    COUNT(DISTINCT creator_person_id) AS distinct_creator_count
  FROM (
    SELECT ct.tag_id, c.creator_person_id
    FROM comment_has_tag_tag ct
    JOIN comment c ON ct.comment_id = c.id
    UNION ALL
    SELECT pt.tag_id, p.creator_person_id
    FROM post_has_tag_tag pt
    JOIN post p ON pt.post_id = p.id
  ) AS combined
  GROUP BY tag_id
),
likes_agg AS (
  SELECT
    t.id AS tag_id,
    COUNT(DISTINCT plp.person_id) AS distinct_liker_count,
    COUNT(*) AS total_likes
  FROM person_likes_post plp
  JOIN post p ON plp.post_id = p.id
  JOIN post_has_tag_tag pt ON p.id = pt.post_id
  JOIN tag t ON pt.tag_id = t.id
  GROUP BY t.id
)
SELECT
  COALESCE(c.tag_id, p.tag_id, cr.tag_id, l.tag_id) AS tag_id,
  COALESCE(c.tag_name, p.tag_name) AS tag_name,
  COALESCE(c.comment_count, 0) AS comment_count,
  COALESCE(p.post_count, 0) AS post_count,
  c.avg_comment_length,
  p.avg_post_length,
  COALESCE(cr.distinct_creator_count, 0) AS distinct_creator_count,
  COALESCE(l.total_likes, 0) AS total_likes,
  COALESCE(l.distinct_liker_count, 0) AS distinct_liker_count
FROM comment_agg c
FULL OUTER JOIN post_agg p ON c.tag_id = p.tag_id
FULL OUTER JOIN creator_agg cr ON COALESCE(c.tag_id, p.tag_id) = cr.tag_id
FULL OUTER JOIN likes_agg l ON COALESCE(c.tag_id, p.tag_id) = l.tag_id
ORDER BY comment_count DESC, post_count DESC
LIMIT 100
