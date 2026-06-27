WITH post_likes AS (
    SELECT
        t.id AS tag_id,
        tc.id AS tag_class_id,
        t.name AS tag_name,
        tc.name AS tag_class_name,
        COUNT(pl.person_id) AS post_likes,
        COUNT(DISTINCT pl.person_id) AS distinct_persons_liked_posts,
        COUNT(p.id) AS post_count,
        AVG(p.length) AS avg_post_length
    FROM post_has_tag_tag pht
    JOIN post p ON pht.post_id = p.id
    JOIN tag t ON pht.tag_id = t.id
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
    LEFT JOIN person_likes_post pl ON pl.post_id = p.id
    GROUP BY t.id, tc.id, t.name, tc.name
),
comment_likes AS (
    SELECT
        t.id AS tag_id,
        tc.id AS tag_class_id,
        t.name AS tag_name,
        tc.name AS tag_class_name,
        COUNT(cl.person_id) AS comment_likes,
        COUNT(DISTINCT cl.person_id) AS distinct_persons_liked_comments,
        COUNT(c.id) AS comment_count,
        AVG(c.length) AS avg_comment_length
    FROM comment_has_tag_tag cht
    JOIN comment c ON cht.comment_id = c.id
    JOIN tag t ON cht.tag_id = t.id
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
    LEFT JOIN person_likes_comment cl ON cl.comment_id = c.id
    GROUP BY t.id, tc.id, t.name, tc.name
)
SELECT
    COALESCE(pl.tag_id, cl.tag_id) AS tag_id,
    COALESCE(pl.tag_name, cl.tag_name) AS tag_name,
    COALESCE(pl.tag_class_id, cl.tag_class_id) AS tag_class_id,
    COALESCE(pl.tag_class_name, cl.tag_class_name) AS tag_class_name,
    COALESCE(pl.post_likes, 0) + COALESCE(cl.comment_likes, 0) AS total_likes,
    COALESCE(pl.distinct_persons_liked_posts, 0) + COALESCE(cl.distinct_persons_liked_comments, 0) AS total_distinct_persons_liked,
    COALESCE(pl.post_count, 0) AS post_count,
    COALESCE(cl.comment_count, 0) AS comment_count,
    COALESCE(pl.avg_post_length, 0) AS avg_post_length,
    COALESCE(cl.avg_comment_length, 0) AS avg_comment_length
FROM post_likes pl
FULL OUTER JOIN comment_likes cl
    ON pl.tag_id = cl.tag_id
ORDER BY total_likes DESC
LIMIT 20
