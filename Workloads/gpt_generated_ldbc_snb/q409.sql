WITH post_agg AS (
    SELECT
        t.type_tag_class_id AS tag_class_id,
        COUNT(DISTINCT p.id) AS num_posts,
        SUM(p.length) AS total_post_length
    FROM
        tag t
        JOIN post_has_tag_tag pht ON pht.tag_id = t.id
        JOIN post p ON p.id = pht.post_id
    GROUP BY
        t.type_tag_class_id
),
comment_agg AS (
    SELECT
        t.type_tag_class_id AS tag_class_id,
        COUNT(DISTINCT c.id) AS num_comments,
        AVG(c.length) AS avg_comment_length
    FROM
        tag t
        JOIN comment_has_tag_tag cht ON cht.tag_id = t.id
        JOIN comment c ON c.id = cht.comment_id
    GROUP BY
        t.type_tag_class_id
)
SELECT
    tc.id AS tag_class_id,
    tc.name AS tag_class_name,
    COALESCE(pa.num_posts, 0) AS num_posts,
    COALESCE(pa.total_post_length, 0) AS total_post_length,
    COALESCE(ca.num_comments, 0) AS num_comments,
    COALESCE(ca.avg_comment_length, 0) AS avg_comment_length
FROM
    tag_class tc
    LEFT JOIN post_agg pa ON pa.tag_class_id = tc.id
    LEFT JOIN comment_agg ca ON ca.tag_class_id = tc.id
ORDER BY
    num_posts DESC,
    num_comments DESC
LIMIT 20
