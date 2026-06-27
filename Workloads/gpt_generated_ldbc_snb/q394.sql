WITH tag_comment_stats AS (
    SELECT
        t.id AS tag_id,
        t.name AS tag_name,
        t.type_tag_class_id,
        COUNT(*) AS comment_tag_count,
        COUNT(DISTINCT cht.comment_id) AS distinct_comment_count,
        MIN(cht.creation_date) AS first_tagged_date,
        MAX(cht.creation_date) AS last_tagged_date
    FROM comment_has_tag_tag cht
    JOIN tag t
        ON cht.tag_id = t.id
    GROUP BY
        t.id,
        t.name,
        t.type_tag_class_id
)
SELECT
    tag_id,
    tag_name,
    type_tag_class_id,
    comment_tag_count,
    distinct_comment_count,
    first_tagged_date,
    last_tagged_date,
    CAST(distinct_comment_count AS double) / comment_tag_count AS distinct_comment_ratio,
    ROW_NUMBER() OVER (ORDER BY comment_tag_count DESC) AS tag_rank
FROM tag_comment_stats
WHERE comment_tag_count > 0
ORDER BY tag_rank
LIMIT 10
