-- Top 10 tag classes by combined post and comment activity
WITH post_tagged AS (
    SELECT DISTINCT
        p.id AS post_id,
        p.length AS post_length,
        p.creator_person_id AS creator_id,
        tc.id AS tag_class_id,
        tc.name AS tag_class_name
    FROM post_has_tag_tag pt
    JOIN post p ON pt.post_id = p.id
    JOIN tag t ON pt.tag_id = t.id
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
),
post_stats AS (
    SELECT
        tag_class_id,
        tag_class_name,
        COUNT(*) AS post_count,
        SUM(post_length) AS total_post_length,
        AVG(post_length) AS avg_post_length,
        COUNT(DISTINCT creator_id) AS distinct_post_creators
    FROM post_tagged
    GROUP BY tag_class_id, tag_class_name
),
comment_tagged AS (
    SELECT DISTINCT
        c.id AS comment_id,
        c.length AS comment_length,
        c.creator_person_id AS creator_id,
        tc.id AS tag_class_id,
        tc.name AS tag_class_name
    FROM comment_has_tag_tag ct
    JOIN comment c ON ct.comment_id = c.id
    JOIN tag t ON ct.tag_id = t.id
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
),
comment_stats AS (
    SELECT
        tag_class_id,
        tag_class_name,
        COUNT(*) AS comment_count,
        SUM(comment_length) AS total_comment_length,
        AVG(comment_length) AS avg_comment_length,
        COUNT(DISTINCT creator_id) AS distinct_comment_creators
    FROM comment_tagged
    GROUP BY tag_class_id, tag_class_name
)
SELECT
    COALESCE(p.tag_class_id, c.tag_class_id) AS tag_class_id,
    COALESCE(p.tag_class_name, c.tag_class_name) AS tag_class_name,
    COALESCE(p.post_count, 0) AS post_count,
    COALESCE(c.comment_count, 0) AS comment_count,
    COALESCE(p.post_count, 0) + COALESCE(c.comment_count, 0) AS total_activity,
    p.avg_post_length,
    c.avg_comment_length,
    COALESCE(p.distinct_post_creators, 0) + COALESCE(c.distinct_comment_creators, 0) AS distinct_creators
FROM post_stats p
FULL OUTER JOIN comment_stats c
    ON p.tag_class_id = c.tag_class_id
ORDER BY total_activity DESC
LIMIT 10
