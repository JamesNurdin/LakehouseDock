WITH post_tag_likes AS (
    SELECT
        tc.id AS tag_class_id,
        tc.name AS tag_class_name,
        COUNT(DISTINCT ph.post_id) AS post_cnt,
        COUNT(pl.person_id) AS post_like_cnt,
        SUM(p.length) AS total_post_length,
        AVG(p.length) AS avg_post_length
    FROM post_has_tag_tag ph
    JOIN post p
        ON ph.post_id = p.id
    JOIN tag t
        ON ph.tag_id = t.id
    JOIN tag_class tc
        ON t.type_tag_class_id = tc.id
    LEFT JOIN person_likes_post pl
        ON pl.post_id = p.id
    GROUP BY tc.id, tc.name
),
comment_tag_likes AS (
    SELECT
        tc.id AS tag_class_id,
        tc.name AS tag_class_name,
        COUNT(DISTINCT ch.comment_id) AS comment_cnt,
        COUNT(cl.person_id) AS comment_like_cnt,
        SUM(c.length) AS total_comment_length,
        AVG(c.length) AS avg_comment_length
    FROM comment_has_tag_tag ch
    JOIN comment c
        ON ch.comment_id = c.id
    JOIN tag t
        ON ch.tag_id = t.id
    JOIN tag_class tc
        ON t.type_tag_class_id = tc.id
    LEFT JOIN person_likes_comment cl
        ON cl.comment_id = c.id
    GROUP BY tc.id, tc.name
)
SELECT
    COALESCE(p.tag_class_id, c.tag_class_id) AS tag_class_id,
    COALESCE(p.tag_class_name, c.tag_class_name) AS tag_class_name,
    COALESCE(p.post_cnt, 0) AS post_cnt,
    COALESCE(c.comment_cnt, 0) AS comment_cnt,
    COALESCE(p.post_like_cnt, 0) AS post_like_cnt,
    COALESCE(c.comment_like_cnt, 0) AS comment_like_cnt,
    COALESCE(p.total_post_length, 0) AS total_post_length,
    COALESCE(c.total_comment_length, 0) AS total_comment_length,
    (COALESCE(p.post_cnt, 0) + COALESCE(c.comment_cnt, 0) + COALESCE(p.post_like_cnt, 0) + COALESCE(c.comment_like_cnt, 0)) AS total_activity
FROM post_tag_likes p
FULL OUTER JOIN comment_tag_likes c
    ON p.tag_class_id = c.tag_class_id
ORDER BY total_activity DESC
LIMIT 10
