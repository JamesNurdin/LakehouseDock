WITH tag_post_metrics AS (
    SELECT
        t.id AS tag_id,
        t.name AS tag_name,
        tc.name AS tag_class_name,
        COUNT(p.id) AS post_count,
        AVG(p.length) AS avg_post_length,
        COUNT(DISTINCT p.creator_person_id) AS distinct_post_creators
    FROM tag t
    JOIN post_has_tag_tag pht ON pht.tag_id = t.id
    JOIN post p ON p.id = pht.post_id
    LEFT JOIN tag_class tc ON t.type_tag_class_id = tc.id
    GROUP BY t.id, t.name, tc.name
),
tag_comment_metrics AS (
    SELECT
        t.id AS tag_id,
        t.name AS tag_name,
        tc.name AS tag_class_name,
        COUNT(c.id) AS comment_count,
        AVG(c.length) AS avg_comment_length,
        COUNT(DISTINCT c.creator_person_id) AS distinct_comment_creators
    FROM tag t
    JOIN comment_has_tag_tag cht ON cht.tag_id = t.id
    JOIN comment c ON c.id = cht.comment_id
    LEFT JOIN tag_class tc ON t.type_tag_class_id = tc.id
    GROUP BY t.id, t.name, tc.name
)
SELECT
    COALESCE(p.tag_id, cm.tag_id) AS tag_id,
    COALESCE(p.tag_name, cm.tag_name) AS tag_name,
    COALESCE(p.tag_class_name, cm.tag_class_name) AS tag_class_name,
    COALESCE(p.post_count, 0) AS post_count,
    COALESCE(cm.comment_count, 0) AS comment_count,
    COALESCE(p.avg_post_length, 0) AS avg_post_length,
    COALESCE(cm.avg_comment_length, 0) AS avg_comment_length,
    COALESCE(p.distinct_post_creators, 0) AS distinct_post_creators,
    COALESCE(cm.distinct_comment_creators, 0) AS distinct_comment_creators,
    (COALESCE(p.post_count, 0) + COALESCE(cm.comment_count, 0)) AS total_content_count
FROM tag_post_metrics p
FULL OUTER JOIN tag_comment_metrics cm ON p.tag_id = cm.tag_id
ORDER BY total_content_count DESC
LIMIT 10
