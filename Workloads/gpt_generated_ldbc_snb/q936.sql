WITH comment_likes AS (
    SELECT
        cht.tag_id,
        COUNT(plc.person_id) AS comment_like_cnt
    FROM comment_has_tag_tag cht
    JOIN comment c ON cht.comment_id = c.id
    LEFT JOIN person_likes_comment plc ON plc.comment_id = c.id
    GROUP BY cht.tag_id
),
post_likes AS (
    SELECT
        pht.tag_id,
        COUNT(plp.person_id) AS post_like_cnt
    FROM post_has_tag_tag pht
    JOIN post p ON pht.post_id = p.id
    LEFT JOIN person_likes_post plp ON plp.post_id = p.id
    GROUP BY pht.tag_id
),
tag_aggregated AS (
    SELECT
        t.id AS tag_id,
        t.name AS tag_name,
        COALESCE(cl.comment_like_cnt, 0) + COALESCE(pl.post_like_cnt, 0) AS total_likes
    FROM tag t
    LEFT JOIN comment_likes cl ON cl.tag_id = t.id
    LEFT JOIN post_likes pl ON pl.tag_id = t.id
)
SELECT
    tag_name,
    total_likes
FROM tag_aggregated
ORDER BY total_likes DESC
LIMIT 10
