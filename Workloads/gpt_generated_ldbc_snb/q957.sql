WITH comment_tag AS (
    SELECT c.id AS comment_id,
           c.length,
           c.location_country_id,
           cht.tag_id
    FROM comment c
    JOIN comment_has_tag_tag cht
      ON cht.comment_id = c.id
),
comment_likes AS (
    SELECT ct.comment_id,
           ct.tag_id,
           COUNT(plc.person_id) AS like_cnt
    FROM comment_tag ct
    LEFT JOIN person_likes_comment plc
      ON plc.comment_id = ct.comment_id
    GROUP BY ct.comment_id, ct.tag_id
),
comment_replies AS (
    SELECT parent.id AS parent_comment_id,
           COUNT(child.id) AS reply_cnt
    FROM comment parent
    JOIN comment child
      ON child.parent_comment_id = parent.id
    GROUP BY parent.id
)
SELECT p_country.name AS country_name,
       p_region.name AS region_name,
       t.name AS tag_name,
       COUNT(DISTINCT ct.comment_id) AS comment_cnt,
       SUM(COALESCE(cl.like_cnt, 0)) AS total_likes,
       AVG(ct.length) AS avg_comment_length,
       SUM(COALESCE(cr.reply_cnt, 0)) AS total_replies
FROM comment_tag ct
JOIN tag t
  ON t.id = ct.tag_id
JOIN place p_country
  ON p_country.id = ct.location_country_id
LEFT JOIN place p_region
  ON p_country.part_of_place_id = p_region.id
LEFT JOIN comment_likes cl
  ON cl.comment_id = ct.comment_id AND cl.tag_id = ct.tag_id
LEFT JOIN comment_replies cr
  ON cr.parent_comment_id = ct.comment_id
GROUP BY p_country.name, p_region.name, t.name
ORDER BY total_likes DESC
LIMIT 100
