WITH post_likes AS (
    SELECT t.id AS tag_id,
           t.name AS tag_name,
           tc.name AS tag_class_name,
           COUNT(pl.person_id) AS post_likes,
           COUNT(DISTINCT pl.person_id) AS post_like_persons,
           AVG(p.length) AS avg_post_length
    FROM tag t
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
    JOIN post_has_tag_tag pht ON pht.tag_id = t.id
    JOIN post p ON p.id = pht.post_id
    JOIN person_likes_post pl ON pl.post_id = p.id
    GROUP BY t.id, t.name, tc.name
),
comment_likes AS (
    SELECT t.id AS tag_id,
           t.name AS tag_name,
           tc.name AS tag_class_name,
           COUNT(cl.person_id) AS comment_likes,
           COUNT(DISTINCT cl.person_id) AS comment_like_persons,
           AVG(c.length) AS avg_comment_length
    FROM tag t
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
    JOIN comment_has_tag_tag cht ON cht.tag_id = t.id
    JOIN comment c ON c.id = cht.comment_id
    JOIN person_likes_comment cl ON cl.comment_id = c.id
    GROUP BY t.id, t.name, tc.name
),
person_likes_union AS (
    SELECT t.id AS tag_id, pl.person_id
    FROM tag t
    JOIN post_has_tag_tag pht ON pht.tag_id = t.id
    JOIN post p ON p.id = pht.post_id
    JOIN person_likes_post pl ON pl.post_id = p.id
    UNION
    SELECT t.id AS tag_id, cl.person_id
    FROM tag t
    JOIN comment_has_tag_tag cht ON cht.tag_id = t.id
    JOIN comment c ON c.id = cht.comment_id
    JOIN person_likes_comment cl ON cl.comment_id = c.id
)
SELECT COALESCE(pl.tag_id, cl.tag_id) AS tag_id,
       COALESCE(pl.tag_name, cl.tag_name) AS tag_name,
       COALESCE(pl.tag_class_name, cl.tag_class_name) AS tag_class_name,
       COALESCE(pl.post_likes, 0) + COALESCE(cl.comment_likes, 0) AS total_likes,
       (
           SELECT COUNT(DISTINCT person_id)
           FROM person_likes_union pu
           WHERE pu.tag_id = COALESCE(pl.tag_id, cl.tag_id)
       ) AS distinct_like_persons,
       COALESCE(pl.avg_post_length, 0) AS avg_post_length,
       COALESCE(cl.avg_comment_length, 0) AS avg_comment_length
FROM post_likes pl
FULL OUTER JOIN comment_likes cl ON pl.tag_id = cl.tag_id
ORDER BY total_likes DESC
LIMIT 10
