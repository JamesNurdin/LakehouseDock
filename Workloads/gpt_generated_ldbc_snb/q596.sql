WITH comment_stats AS (
    SELECT
        p_parent.id AS region_id,
        p_parent.name AS region_name,
        COUNT(*) AS total_comments,
        AVG(c.length) AS avg_comment_length,
        SUM(CASE WHEN c.parent_comment_id IS NOT NULL THEN 1 ELSE 0 END) AS reply_comments,
        SUM(CASE WHEN c.parent_comment_id IS NULL THEN 1 ELSE 0 END) AS top_level_comments
    FROM comment c
    JOIN place p_country ON c.location_country_id = p_country.id
    JOIN place p_parent ON p_country.part_of_place_id = p_parent.id
    GROUP BY p_parent.id, p_parent.name
),
organisation_stats AS (
    SELECT
        p_parent.id AS region_id,
        COUNT(DISTINCT o.id) AS organisation_count
    FROM organisation o
    JOIN place p_loc ON o.location_place_id = p_loc.id
    JOIN place p_parent ON p_loc.part_of_place_id = p_parent.id
    GROUP BY p_parent.id
)
SELECT
    cs.region_name,
    cs.total_comments,
    cs.avg_comment_length,
    cs.reply_comments,
    cs.top_level_comments,
    os.organisation_count
FROM comment_stats cs
LEFT JOIN organisation_stats os ON cs.region_id = os.region_id
ORDER BY cs.total_comments DESC
LIMIT 100
