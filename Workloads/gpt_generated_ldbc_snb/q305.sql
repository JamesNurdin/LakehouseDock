WITH post_likes AS (
    SELECT
        pht.tag_id,
        COUNT(*) AS post_like_count
    FROM post_has_tag_tag pht
    JOIN post p ON pht.post_id = p.id
    JOIN person_likes_post plc ON plc.post_id = p.id
    GROUP BY pht.tag_id
),
comment_likes AS (
    SELECT
        cht.tag_id,
        COUNT(*) AS comment_like_count
    FROM comment_has_tag_tag cht
    JOIN comment c ON cht.comment_id = c.id
    JOIN person_likes_comment plc ON plc.comment_id = c.id
    GROUP BY cht.tag_id
),
tag_aggregates AS (
    SELECT
        t.id AS tag_id,
        t.name AS tag_name,
        COALESCE(pl.post_like_count, 0) AS post_like_count,
        COALESCE(cl.comment_like_count, 0) AS comment_like_count,
        COALESCE(pl.post_like_count, 0) + COALESCE(cl.comment_like_count, 0) AS total_like_count
    FROM tag t
    LEFT JOIN post_likes pl ON pl.tag_id = t.id
    LEFT JOIN comment_likes cl ON cl.tag_id = t.id
)
SELECT
    tag_id,
    tag_name,
    post_like_count,
    comment_like_count,
    total_like_count
FROM tag_aggregates
ORDER BY total_like_count DESC
LIMIT 10
