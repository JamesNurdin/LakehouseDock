WITH comment_likes AS (
    SELECT
        cht.tag_id,
        plc.person_id
    FROM comment_has_tag_tag cht
    JOIN comment c
        ON cht.comment_id = c.id
    JOIN person_likes_comment plc
        ON c.id = plc.comment_id
),
post_likes AS (
    SELECT
        pht.tag_id,
        plp.person_id
    FROM post_has_tag_tag pht
    JOIN post p
        ON pht.post_id = p.id
    JOIN person_likes_post plp
        ON p.id = plp.post_id
),
likes_per_tag AS (
    SELECT tag_id, person_id FROM comment_likes
    UNION ALL
    SELECT tag_id, person_id FROM post_likes
)
SELECT
    t.id AS tag_id,
    t.name AS tag_name,
    COUNT(*) AS total_likes,
    COUNT(DISTINCT l.person_id) AS distinct_likers
FROM likes_per_tag l
JOIN tag t
    ON l.tag_id = t.id
GROUP BY t.id, t.name
ORDER BY total_likes DESC
LIMIT 10
