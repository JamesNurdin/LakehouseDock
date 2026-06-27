WITH tag_likes AS (
    -- Likes on comments, attributed to the tag of the comment and the city of the liker
    SELECT
        t.id AS tag_id,
        t.name AS tag_name,
        tc.id AS tag_class_id,
        tc.name AS tag_class_name,
        pc.id AS city_id,
        pc.name AS city_name,
        COUNT(*) AS like_cnt
    FROM person_likes_comment plc
    JOIN person per ON plc.person_id = per.id
    JOIN place pc ON per.location_city_id = pc.id
    JOIN comment c ON plc.comment_id = c.id
    JOIN comment_has_tag_tag cht ON cht.comment_id = c.id
    JOIN tag t ON cht.tag_id = t.id
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
    GROUP BY t.id, t.name, tc.id, tc.name, pc.id, pc.name

    UNION ALL

    -- Likes on posts, attributed to the tag of the post and the city of the liker
    SELECT
        t.id AS tag_id,
        t.name AS tag_name,
        tc.id AS tag_class_id,
        tc.name AS tag_class_name,
        pc.id AS city_id,
        pc.name AS city_name,
        COUNT(*) AS like_cnt
    FROM person_likes_post plp
    JOIN person per ON plp.person_id = per.id
    JOIN place pc ON per.location_city_id = pc.id
    JOIN post p ON plp.post_id = p.id
    JOIN post_has_tag_tag pht ON pht.post_id = p.id
    JOIN tag t ON pht.tag_id = t.id
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
    GROUP BY t.id, t.name, tc.id, tc.name, pc.id, pc.name
)
SELECT
    tag_id,
    tag_name,
    tag_class_id,
    tag_class_name,
    city_id,
    city_name,
    SUM(like_cnt) AS total_like_cnt
FROM tag_likes
GROUP BY tag_id, tag_name, tag_class_id, tag_class_name, city_id, city_name
ORDER BY total_like_cnt DESC
LIMIT 20
