WITH post_stats AS (
    SELECT p.id AS post_id,
           p.length AS post_length,
           COALESCE(pl.like_count, 0) AS like_count
    FROM post p
    LEFT JOIN (
        SELECT post_id, COUNT(*) AS like_count
        FROM person_likes_post
        GROUP BY post_id
    ) pl ON pl.post_id = p.id
),
post_tag_class AS (
    SELECT DISTINCT
        ps.post_id,
        ps.post_length,
        ps.like_count,
        tc.id AS tag_class_id,
        tc.name AS tag_class_name
    FROM post_stats ps
    JOIN post_has_tag_tag pht ON pht.post_id = ps.post_id
    JOIN tag t ON t.id = pht.tag_id
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
),
post_agg AS (
    SELECT
        tag_class_id,
        tag_class_name,
        COUNT(DISTINCT post_id) AS post_count,
        SUM(like_count) AS total_post_likes,
        AVG(post_length) AS avg_post_length
    FROM post_tag_class
    GROUP BY tag_class_id, tag_class_name
),
comment_stats AS (
    SELECT c.id AS comment_id,
           c.length AS comment_length,
           COALESCE(cl.like_count, 0) AS like_count
    FROM comment c
    LEFT JOIN (
        SELECT comment_id, COUNT(*) AS like_count
        FROM person_likes_comment
        GROUP BY comment_id
    ) cl ON cl.comment_id = c.id
),
comment_tag_class AS (
    SELECT DISTINCT
        cs.comment_id,
        cs.comment_length,
        cs.like_count,
        tc.id AS tag_class_id,
        tc.name AS tag_class_name
    FROM comment_stats cs
    JOIN comment_has_tag_tag cht ON cht.comment_id = cs.comment_id
    JOIN tag t ON t.id = cht.tag_id
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
),
comment_agg AS (
    SELECT
        tag_class_id,
        tag_class_name,
        COUNT(DISTINCT comment_id) AS comment_count,
        SUM(like_count) AS total_comment_likes,
        AVG(comment_length) AS avg_comment_length
    FROM comment_tag_class
    GROUP BY tag_class_id, tag_class_name
)
SELECT
    COALESCE(p.tag_class_id, c.tag_class_id) AS tag_class_id,
    COALESCE(p.tag_class_name, c.tag_class_name) AS tag_class_name,
    COALESCE(p.post_count, 0) AS post_count,
    COALESCE(c.comment_count, 0) AS comment_count,
    COALESCE(p.total_post_likes, 0) AS total_post_likes,
    COALESCE(c.total_comment_likes, 0) AS total_comment_likes,
    p.avg_post_length,
    c.avg_comment_length
FROM post_agg p
FULL OUTER JOIN comment_agg c
    ON p.tag_class_id = c.tag_class_id
ORDER BY total_post_likes DESC, tag_class_id
