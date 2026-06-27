WITH comment_tag_stats AS (
   SELECT
       t.id AS tag_id,
       t.name AS tag_name,
       tc.name AS tag_class_name,
       COUNT(DISTINCT c.id) AS comment_count,
       AVG(c.length) AS avg_comment_length,
       COUNT(plc.person_id) AS total_likes,
       COUNT(DISTINCT plc.person_id) AS distinct_likers
   FROM comment_has_tag_tag cht
   JOIN comment c ON cht.comment_id = c.id
   JOIN tag t ON cht.tag_id = t.id
   LEFT JOIN person_likes_comment plc ON plc.comment_id = c.id
   LEFT JOIN tag_class tc ON t.type_tag_class_id = tc.id
   GROUP BY t.id, t.name, tc.name
),
post_tag_stats AS (
   SELECT
       t.id AS tag_id,
       COUNT(DISTINCT p.id) AS post_count,
       AVG(p.length) AS avg_post_length
   FROM post_has_tag_tag pht
   JOIN post p ON pht.post_id = p.id
   JOIN tag t ON pht.tag_id = t.id
   GROUP BY t.id
)
SELECT
   ct.tag_id,
   ct.tag_name,
   ct.tag_class_name,
   ct.comment_count,
   ct.avg_comment_length,
   COALESCE(ct.total_likes, 0) AS total_likes,
   COALESCE(ct.distinct_likers, 0) AS distinct_likers,
   COALESCE(pt.post_count, 0) AS post_count,
   COALESCE(pt.avg_post_length, 0) AS avg_post_length,
   (ct.comment_count + COALESCE(pt.post_count, 0)) AS total_items
FROM comment_tag_stats ct
LEFT JOIN post_tag_stats pt ON ct.tag_id = pt.tag_id
ORDER BY total_items DESC
LIMIT 10
