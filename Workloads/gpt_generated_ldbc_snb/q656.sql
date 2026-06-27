WITH comment_likes AS (
  SELECT comment_id,
         COUNT(DISTINCT person_id) AS like_cnt
  FROM person_likes_comment
  GROUP BY comment_id
),
comment_tag AS (
  SELECT
    c.id AS comment_id,
    c.length,
    c.location_country_id,
    COALESCE(cl.like_cnt, 0) AS like_cnt,
    cht.tag_id,
    c.creator_person_id
  FROM comment c
  LEFT JOIN comment_likes cl ON c.id = cl.comment_id
  JOIN comment_has_tag_tag cht ON cht.comment_id = c.id
)
SELECT
  t.name AS tag_name,
  p.name AS country_name,
  COUNT(DISTINCT ctg.comment_id) AS comment_count,
  AVG(ctg.length) AS avg_comment_length,
  SUM(ctg.like_cnt) AS total_likes,
  COUNT(DISTINCT ctg.creator_person_id) AS distinct_commenters
FROM comment_tag ctg
JOIN tag t ON ctg.tag_id = t.id
JOIN place p ON ctg.location_country_id = p.id
GROUP BY t.name, p.name
ORDER BY total_likes DESC
LIMIT 10
