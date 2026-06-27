WITH post_tags AS (
  SELECT
    p.id AS post_id,
    p.length AS length,
    p.creator_person_id AS creator_id,
    p.location_country_id AS country_id,
    t.id AS tag_id,
    tc.id AS tag_class_id,
    tc.name AS tag_class_name
  FROM post p
  JOIN post_has_tag_tag pht
    ON p.id = pht.post_id
  JOIN tag t
    ON pht.tag_id = t.id
  JOIN tag_class tc
    ON t.type_tag_class_id = tc.id
),
comment_tags AS (
  SELECT
    c.id AS comment_id,
    c.length AS length,
    c.creator_person_id AS creator_id,
    c.location_country_id AS country_id,
    t.id AS tag_id,
    tc.id AS tag_class_id,
    tc.name AS tag_class_name
  FROM comment c
  JOIN comment_has_tag_tag cht
    ON c.id = cht.comment_id
  JOIN tag t
    ON cht.tag_id = t.id
  JOIN tag_class tc
    ON t.type_tag_class_id = tc.id
),
combined AS (
  SELECT
    country_id,
    tag_class_id,
    tag_class_name,
    'post' AS entity_type,
    length,
    creator_id
  FROM post_tags
  UNION ALL
  SELECT
    country_id,
    tag_class_id,
    tag_class_name,
    'comment' AS entity_type,
    length,
    creator_id
  FROM comment_tags
)
SELECT
  pl.name AS country_name,
  c.tag_class_name,
  SUM(CASE WHEN c.entity_type = 'post' THEN 1 ELSE 0 END) AS post_count,
  SUM(CASE WHEN c.entity_type = 'comment' THEN 1 ELSE 0 END) AS comment_count,
  AVG(CASE WHEN c.entity_type = 'post' THEN c.length END) AS avg_post_length,
  AVG(CASE WHEN c.entity_type = 'comment' THEN c.length END) AS avg_comment_length,
  COUNT(DISTINCT IF(c.entity_type = 'post', c.creator_id, NULL)) AS distinct_post_creators,
  COUNT(DISTINCT IF(c.entity_type = 'comment', c.creator_id, NULL)) AS distinct_comment_creators
FROM combined c
JOIN place pl
  ON c.country_id = pl.id
GROUP BY pl.name, c.tag_class_name
ORDER BY pl.name, c.tag_class_name
