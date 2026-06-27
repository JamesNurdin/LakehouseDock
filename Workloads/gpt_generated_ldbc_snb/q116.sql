WITH post_stats AS (
    SELECT
        p.location_country_id AS country_id,
        p.language,
        COUNT(*) AS post_count,
        SUM(p.length) AS total_post_length,
        AVG(p.length) AS avg_post_length
    FROM post p
    GROUP BY p.location_country_id, p.language
),
comment_stats AS (
    SELECT
        c.location_country_id AS country_id,
        COUNT(*) AS comment_count,
        SUM(c.length) AS total_comment_length,
        AVG(c.length) AS avg_comment_length,
        COUNT(CASE WHEN c.parent_comment_id IS NULL THEN 1 END) AS top_level_comment_count
    FROM comment c
    GROUP BY c.location_country_id
),
place_hierarchy AS (
    SELECT
        pc.id AS country_id,
        pc.name AS country_name,
        pc.type AS country_type,
        pp.id AS parent_id,
        pp.name AS parent_name,
        pp.type AS parent_type
    FROM place pc
    LEFT JOIN place pp ON pc.part_of_place_id = pp.id
)
SELECT
    ph.country_name,
    ph.country_type,
    ph.parent_name,
    ph.parent_type,
    ps.language,
    ps.post_count,
    ps.total_post_length,
    ps.avg_post_length,
    cs.comment_count,
    cs.top_level_comment_count,
    cs.total_comment_length,
    cs.avg_comment_length
FROM place_hierarchy ph
LEFT JOIN post_stats ps ON ph.country_id = ps.country_id
LEFT JOIN comment_stats cs ON ph.country_id = cs.country_id
ORDER BY ph.country_name, ps.language
