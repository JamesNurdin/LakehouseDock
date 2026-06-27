WITH post_likes AS (
    SELECT pht.tag_id,
           COUNT(plp.person_id) AS post_like_cnt
    FROM post_has_tag_tag AS pht
    JOIN post AS p
      ON pht.post_id = p.id
    JOIN person_likes_post AS plp
      ON plp.post_id = p.id
    GROUP BY pht.tag_id
),
comment_likes AS (
    SELECT cht.tag_id,
           COUNT(plc.person_id) AS comment_like_cnt
    FROM comment_has_tag_tag AS cht
    JOIN comment AS c
      ON cht.comment_id = c.id
    JOIN person_likes_comment AS plc
      ON plc.comment_id = c.id
    GROUP BY cht.tag_id
),
tag_aggregates AS (
    SELECT t.id AS tag_id,
           t.name AS tag_name,
           COALESCE(pl.post_like_cnt, 0) AS post_like_cnt,
           COALESCE(cl.comment_like_cnt, 0) AS comment_like_cnt,
           COALESCE(pl.post_like_cnt, 0) + COALESCE(cl.comment_like_cnt, 0) AS total_like_cnt
    FROM tag AS t
    LEFT JOIN post_likes AS pl
      ON pl.tag_id = t.id
    LEFT JOIN comment_likes AS cl
      ON cl.tag_id = t.id
)
SELECT tag_name,
       post_like_cnt,
       comment_like_cnt,
       total_like_cnt
FROM tag_aggregates
ORDER BY total_like_cnt DESC
LIMIT 20
