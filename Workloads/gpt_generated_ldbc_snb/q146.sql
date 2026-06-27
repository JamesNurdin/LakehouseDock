WITH comment_likes AS (
    SELECT comment_id, COUNT(*) AS like_cnt
    FROM person_likes_comment
    GROUP BY comment_id
),
comment_tags AS (
    SELECT comment_id, tag_id
    FROM comment_has_tag_tag
)
SELECT
    pl.id AS country_id,
    pl.name AS country_name,
    COUNT(DISTINCT c.id) AS comment_count,
    AVG(c.length) AS avg_comment_length,
    COALESCE(SUM(cl.like_cnt), 0) AS total_likes,
    COUNT(DISTINCT t.id) AS distinct_tag_count,
    COUNT(DISTINCT o.id) AS organisation_count
FROM place pl
LEFT JOIN comment c
    ON c.location_country_id = pl.id
LEFT JOIN comment_likes cl
    ON cl.comment_id = c.id
LEFT JOIN comment_tags ct
    ON ct.comment_id = c.id
LEFT JOIN tag t
    ON t.id = ct.tag_id
LEFT JOIN organisation o
    ON o.location_place_id = pl.id
GROUP BY pl.id, pl.name
HAVING COUNT(DISTINCT c.id) >= 100
ORDER BY comment_count DESC
LIMIT 50
