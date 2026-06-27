WITH post_likes AS (
    SELECT
        t.id AS tag_id,
        t.name AS tag_name,
        tc.id AS tag_class_id,
        tc.name AS tag_class_name,
        COUNT(pl.person_id) AS post_like_count,
        COUNT(DISTINCT pl.person_id) AS distinct_persons_post_like
    FROM post_has_tag_tag pht
    JOIN post p ON pht.post_id = p.id
    JOIN tag t ON pht.tag_id = t.id
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
    JOIN person_likes_post pl ON pl.post_id = p.id
    GROUP BY t.id, t.name, tc.id, tc.name
),
comment_likes AS (
    SELECT
        t.id AS tag_id,
        t.name AS tag_name,
        tc.id AS tag_class_id,
        tc.name AS tag_class_name,
        COUNT(cl.person_id) AS comment_like_count,
        COUNT(DISTINCT cl.person_id) AS distinct_persons_comment_like
    FROM comment_has_tag_tag cht
    JOIN comment c ON cht.comment_id = c.id
    JOIN tag t ON cht.tag_id = t.id
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
    JOIN person_likes_comment cl ON cl.comment_id = c.id
    GROUP BY t.id, t.name, tc.id, tc.name
)
SELECT
    COALESCE(pl.tag_id, cl.tag_id) AS tag_id,
    COALESCE(pl.tag_name, cl.tag_name) AS tag_name,
    COALESCE(pl.tag_class_id, cl.tag_class_id) AS tag_class_id,
    COALESCE(pl.tag_class_name, cl.tag_class_name) AS tag_class_name,
    COALESCE(pl.post_like_count, 0) AS post_like_count,
    COALESCE(cl.comment_like_count, 0) AS comment_like_count,
    (COALESCE(pl.distinct_persons_post_like, 0) + COALESCE(cl.distinct_persons_comment_like, 0)) AS distinct_persons_like_total
FROM post_likes pl
FULL OUTER JOIN comment_likes cl
    ON pl.tag_id = cl.tag_id
ORDER BY post_like_count DESC, comment_like_count DESC
LIMIT 100
