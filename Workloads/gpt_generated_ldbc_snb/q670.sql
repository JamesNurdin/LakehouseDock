WITH comment_likes AS (
    SELECT
        tc.id AS tag_class_id,
        tc.name AS tag_class_name,
        COUNT(*) AS comment_like_cnt
    FROM person_likes_comment plc
    JOIN person p ON plc.person_id = p.id
    JOIN place pl_city ON p.location_city_id = pl_city.id
    JOIN comment c ON plc.comment_id = c.id
    JOIN comment_has_tag_tag c_ht ON c.id = c_ht.comment_id
    JOIN tag t ON c_ht.tag_id = t.id
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
    WHERE pl_city.name = 'New York'
    GROUP BY tc.id, tc.name
),
post_likes AS (
    SELECT
        tc.id AS tag_class_id,
        tc.name AS tag_class_name,
        COUNT(*) AS post_like_cnt
    FROM person_likes_post plp
    JOIN person p ON plp.person_id = p.id
    JOIN place pl_city ON p.location_city_id = pl_city.id
    JOIN post po ON plp.post_id = po.id
    JOIN post_has_tag_tag p_ht ON po.id = p_ht.post_id
    JOIN tag t ON p_ht.tag_id = t.id
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
    WHERE pl_city.name = 'New York'
    GROUP BY tc.id, tc.name
)
SELECT
    COALESCE(cl.tag_class_id, pl.tag_class_id) AS tag_class_id,
    COALESCE(cl.tag_class_name, pl.tag_class_name) AS tag_class_name,
    COALESCE(cl.comment_like_cnt, 0) AS comment_like_cnt,
    COALESCE(pl.post_like_cnt, 0) AS post_like_cnt,
    COALESCE(cl.comment_like_cnt, 0) + COALESCE(pl.post_like_cnt, 0) AS total_like_cnt
FROM comment_likes cl
FULL OUTER JOIN post_likes pl
    ON cl.tag_class_id = pl.tag_class_id
ORDER BY total_like_cnt DESC
LIMIT 5
