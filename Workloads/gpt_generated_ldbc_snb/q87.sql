WITH post_likes AS (
    SELECT pht.tag_id AS tag_id,
           COUNT(plp.person_id) AS post_likes
    FROM person_likes_post plp
    JOIN post p ON plp.post_id = p.id
    JOIN post_has_tag_tag pht ON p.id = pht.post_id
    GROUP BY pht.tag_id
),
comment_likes AS (
    SELECT cht.tag_id AS tag_id,
           COUNT(plc.person_id) AS comment_likes
    FROM person_likes_comment plc
    JOIN comment c ON plc.comment_id = c.id
    JOIN comment_has_tag_tag cht ON c.id = cht.comment_id
    GROUP BY cht.tag_id
),
tag_aggregated AS (
    SELECT t.id AS tag_id,
           t.name AS tag_name,
           COALESCE(pl.post_likes, 0) + COALESCE(cl.comment_likes, 0) AS total_likes,
           COALESCE(pl.post_likes, 0) AS post_likes,
           COALESCE(cl.comment_likes, 0) AS comment_likes
    FROM tag t
    LEFT JOIN post_likes pl ON pl.tag_id = t.id
    LEFT JOIN comment_likes cl ON cl.tag_id = t.id
)
SELECT tag_id,
       tag_name,
       total_likes,
       post_likes,
       comment_likes
FROM tag_aggregated
ORDER BY total_likes DESC
LIMIT 10
