WITH post_tag_stats AS (
    SELECT
        tc.id AS tag_class_id,
        tc.name AS tag_class_name,
        COUNT(*) AS post_count,
        COUNT(DISTINCT p.creator_person_id) AS distinct_post_creators,
        SUM(p.length) AS total_post_length,
        AVG(p.length) AS avg_post_length
    FROM post_has_tag_tag pht
    JOIN post p ON pht.post_id = p.id
    JOIN tag t ON pht.tag_id = t.id
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
    GROUP BY tc.id, tc.name
),
comment_tag_stats AS (
    SELECT
        tc.id AS tag_class_id,
        tc.name AS tag_class_name,
        COUNT(*) AS comment_count,
        COUNT(DISTINCT c.creator_person_id) AS distinct_comment_creators,
        SUM(c.length) AS total_comment_length,
        AVG(c.length) AS avg_comment_length
    FROM comment_has_tag_tag cht
    JOIN comment c ON cht.comment_id = c.id
    JOIN tag t ON cht.tag_id = t.id
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
    GROUP BY tc.id, tc.name
)
SELECT
    COALESCE(p.tag_class_name, cm.tag_class_name) AS tag_class_name,
    COALESCE(p.post_count, 0) AS post_count,
    COALESCE(cm.comment_count, 0) AS comment_count,
    COALESCE(p.distinct_post_creators, 0) AS distinct_post_creators,
    COALESCE(cm.distinct_comment_creators, 0) AS distinct_comment_creators,
    COALESCE(p.avg_post_length, 0) AS avg_post_length,
    COALESCE(cm.avg_comment_length, 0) AS avg_comment_length,
    (COALESCE(p.post_count, 0) + COALESCE(cm.comment_count, 0)) AS total_interactions
FROM post_tag_stats p
FULL OUTER JOIN comment_tag_stats cm
    ON p.tag_class_id = cm.tag_class_id
ORDER BY total_interactions DESC
LIMIT 10
