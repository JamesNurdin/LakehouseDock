WITH post_stats AS (
    SELECT
        tc.id AS tag_class_id,
        tc.name AS tag_class_name,
        p.id AS post_id,
        p.length AS post_length,
        p.creator_person_id AS person_id
    FROM post_has_tag_tag pht
    JOIN post p ON pht.post_id = p.id
    JOIN tag t ON pht.tag_id = t.id
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
),
comment_stats AS (
    SELECT
        tc.id AS tag_class_id,
        tc.name AS tag_class_name,
        c.id AS comment_id,
        c.length AS comment_length,
        c.creator_person_id AS person_id
    FROM comment_has_tag_tag cht
    JOIN comment c ON cht.comment_id = c.id
    JOIN tag t ON cht.tag_id = t.id
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
),
post_agg AS (
    SELECT
        tag_class_id,
        tag_class_name,
        COUNT(DISTINCT post_id) AS post_count,
        AVG(post_length) AS avg_post_length
    FROM post_stats
    GROUP BY tag_class_id, tag_class_name
),
comment_agg AS (
    SELECT
        tag_class_id,
        tag_class_name,
        COUNT(DISTINCT comment_id) AS comment_count,
        AVG(comment_length) AS avg_comment_length
    FROM comment_stats
    GROUP BY tag_class_id, tag_class_name
),
person_agg AS (
    SELECT
        tag_class_id,
        tag_class_name,
        COUNT(DISTINCT person_id) AS distinct_person_count
    FROM (
        SELECT tag_class_id, tag_class_name, person_id FROM post_stats
        UNION ALL
        SELECT tag_class_id, tag_class_name, person_id FROM comment_stats
    )
    GROUP BY tag_class_id, tag_class_name
),
combined AS (
    SELECT
        COALESCE(p.tag_class_id, c.tag_class_id, pe.tag_class_id) AS tag_class_id,
        COALESCE(p.tag_class_name, c.tag_class_name, pe.tag_class_name) AS tag_class_name,
        p.post_count,
        p.avg_post_length,
        c.comment_count,
        c.avg_comment_length,
        pe.distinct_person_count
    FROM post_agg p
    FULL OUTER JOIN comment_agg c ON p.tag_class_id = c.tag_class_id
    FULL OUTER JOIN person_agg pe ON COALESCE(p.tag_class_id, c.tag_class_id) = pe.tag_class_id
)
SELECT
    tag_class_id,
    tag_class_name,
    COALESCE(post_count, 0) AS post_count,
    avg_post_length,
    COALESCE(comment_count, 0) AS comment_count,
    avg_comment_length,
    distinct_person_count,
    (COALESCE(post_count, 0) + COALESCE(comment_count, 0)) AS total_activity
FROM combined
ORDER BY total_activity DESC
LIMIT 5
