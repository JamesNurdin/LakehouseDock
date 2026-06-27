WITH comment_tag_stats AS (
    SELECT
        t.id AS tag_id,
        t.name AS tag_name,
        tc.id AS tag_class_id,
        tc.name AS tag_class_name,
        COUNT(DISTINCT c.id) AS comment_count,
        AVG(c.length) AS avg_comment_length,
        COUNT(DISTINCT plc.person_id) AS comment_like_count,
        COUNT(DISTINCT c.creator_person_id) AS distinct_comment_creators,
        COUNT(DISTINCT pl.id) AS distinct_comment_countries
    FROM comment_has_tag_tag ct
    JOIN comment c ON ct.comment_id = c.id
    JOIN tag t ON ct.tag_id = t.id
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
    LEFT JOIN person_likes_comment plc ON plc.comment_id = c.id
    LEFT JOIN place pl ON c.location_country_id = pl.id
    GROUP BY t.id, t.name, tc.id, tc.name
),
post_tag_stats AS (
    SELECT
        t.id AS tag_id,
        t.name AS tag_name,
        tc.id AS tag_class_id,
        tc.name AS tag_class_name,
        COUNT(DISTINCT p.id) AS post_count,
        AVG(p.length) AS avg_post_length,
        COUNT(DISTINCT p.creator_person_id) AS distinct_post_creators,
        COUNT(DISTINCT pl.id) AS distinct_post_countries
    FROM post_has_tag_tag pt
    JOIN post p ON pt.post_id = p.id
    JOIN tag t ON pt.tag_id = t.id
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
    LEFT JOIN place pl ON p.location_country_id = pl.id
    GROUP BY t.id, t.name, tc.id, tc.name
)
SELECT
    COALESCE(cts.tag_id, pts.tag_id) AS tag_id,
    COALESCE(cts.tag_name, pts.tag_name) AS tag_name,
    COALESCE(cts.tag_class_id, pts.tag_class_id) AS tag_class_id,
    COALESCE(cts.tag_class_name, pts.tag_class_name) AS tag_class_name,
    COALESCE(cts.comment_count, 0) AS comment_count,
    COALESCE(cts.avg_comment_length, 0) AS avg_comment_length,
    COALESCE(cts.comment_like_count, 0) AS comment_like_count,
    COALESCE(cts.distinct_comment_creators, 0) AS distinct_comment_creators,
    COALESCE(pts.post_count, 0) AS post_count,
    COALESCE(pts.avg_post_length, 0) AS avg_post_length,
    COALESCE(pts.distinct_post_creators, 0) AS distinct_post_creators,
    COALESCE(cts.distinct_comment_countries, 0) + COALESCE(pts.distinct_post_countries, 0) AS distinct_countries_total
FROM comment_tag_stats cts
FULL OUTER JOIN post_tag_stats pts
    ON cts.tag_id = pts.tag_id
ORDER BY comment_count DESC, post_count DESC
LIMIT 100
