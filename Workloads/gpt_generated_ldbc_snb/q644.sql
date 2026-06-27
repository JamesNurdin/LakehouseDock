WITH tag_comment_counts AS (
    SELECT
        t.type_tag_class_id,
        t.id AS tag_id,
        COUNT(DISTINCT cht.comment_id) AS comment_cnt
    FROM comment_has_tag_tag cht
    JOIN tag t
      ON cht.tag_id = t.id
    GROUP BY t.type_tag_class_id, t.id
),
type_aggregates AS (
    SELECT
        type_tag_class_id,
        COUNT(tag_id) AS tag_cnt,
        SUM(comment_cnt) AS total_comment_cnt,
        AVG(comment_cnt) AS avg_comment_per_tag
    FROM tag_comment_counts
    GROUP BY type_tag_class_id
)
SELECT
    type_tag_class_id,
    tag_cnt,
    total_comment_cnt,
    avg_comment_per_tag
FROM type_aggregates
ORDER BY total_comment_cnt DESC
