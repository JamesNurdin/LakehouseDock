WITH comment_likes AS (
    SELECT
        tc.id AS tag_class_id,
        tc.name AS tag_class_name,
        COUNT(*) AS comment_likes
    FROM person_likes_comment plc
    JOIN person p ON plc.person_id = p.id
    JOIN comment c ON plc.comment_id = c.id
    JOIN comment_has_tag_tag cht ON c.id = cht.comment_id
    JOIN tag t ON cht.tag_id = t.id
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
    WHERE p.gender = 'female'
    GROUP BY tc.id, tc.name
), post_likes AS (
    SELECT
        tc.id AS tag_class_id,
        tc.name AS tag_class_name,
        COUNT(*) AS post_likes
    FROM person_likes_post plp
    JOIN person p ON plp.person_id = p.id
    JOIN post po ON plp.post_id = po.id
    JOIN post_has_tag_tag pht ON po.id = pht.post_id
    JOIN tag t ON pht.tag_id = t.id
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
    WHERE p.gender = 'female'
    GROUP BY tc.id, tc.name
)
SELECT
    COALESCE(cl.tag_class_id, pl.tag_class_id) AS tag_class_id,
    COALESCE(cl.tag_class_name, pl.tag_class_name) AS tag_class_name,
    COALESCE(cl.comment_likes, 0) AS comment_likes,
    COALESCE(pl.post_likes, 0) AS post_likes,
    COALESCE(cl.comment_likes, 0) + COALESCE(pl.post_likes, 0) AS total_likes
FROM comment_likes cl
FULL OUTER JOIN post_likes pl
    ON cl.tag_class_id = pl.tag_class_id
ORDER BY total_likes DESC
LIMIT 10
