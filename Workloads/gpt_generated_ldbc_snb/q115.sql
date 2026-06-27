WITH comment_like_counts AS (
    SELECT
        comment_id,
        COUNT(*) AS like_count
    FROM person_likes_comment
    GROUP BY comment_id
)
SELECT
    o.type AS organisation_type,
    cht.tag_id,
    COUNT(DISTINCT c.id) AS comment_count,
    COALESCE(SUM(cl.like_count), 0) AS total_likes,
    AVG(c.length) AS avg_comment_length,
    COUNT(DISTINCT p.id) AS distinct_creator_count
FROM comment_has_tag_tag cht
JOIN comment c
    ON cht.comment_id = c.id
JOIN person p
    ON c.creator_person_id = p.id
JOIN place city
    ON p.location_city_id = city.id
JOIN organisation o
    ON o.location_place_id = city.id
LEFT JOIN comment_like_counts cl
    ON cl.comment_id = c.id
GROUP BY
    o.type,
    cht.tag_id
ORDER BY total_likes DESC
LIMIT 10
