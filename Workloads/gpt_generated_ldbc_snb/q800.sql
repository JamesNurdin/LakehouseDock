WITH total_comments AS (
    SELECT
        p.id AS country_id,
        p.name AS country_name,
        COUNT(*) AS total_comment_count,
        AVG(c.length) AS avg_comment_length
    FROM comment c
    JOIN place p ON c.location_country_id = p.id
    GROUP BY p.id, p.name
),

tagged_comments AS (
    SELECT
        p.id AS country_id,
        COUNT(DISTINCT c.id) AS tagged_comment_count,
        COUNT(DISTINCT c.creator_person_id) AS distinct_tagged_commenters
    FROM comment_has_tag_tag cht
    JOIN comment c ON cht.comment_id = c.id
    JOIN place p ON c.location_country_id = p.id
    GROUP BY p.id
)
SELECT
    tc.country_name,
    tc.total_comment_count,
    tc.avg_comment_length,
    COALESCE(tg.tagged_comment_count, 0) AS tagged_comment_count,
    CASE WHEN tc.total_comment_count = 0 THEN 0
         ELSE (COALESCE(tg.tagged_comment_count, 0) * 100.0) / tc.total_comment_count END AS pct_tagged_comments,
    COALESCE(tg.distinct_tagged_commenters, 0) AS distinct_tagged_commenters
FROM total_comments tc
LEFT JOIN tagged_comments tg ON tc.country_id = tg.country_id
ORDER BY tc.total_comment_count DESC
