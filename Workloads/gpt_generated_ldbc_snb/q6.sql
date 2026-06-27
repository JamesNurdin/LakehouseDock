WITH city_comments AS (
    SELECT
        p.location_city_id AS city_id,
        pl.name AS city_name,
        COUNT(c.id) AS comment_count,
        AVG(c.length) AS avg_comment_length
    FROM comment c
    JOIN person p ON c.creator_person_id = p.id
    JOIN place pl ON p.location_city_id = pl.id
    GROUP BY p.location_city_id, pl.name
),
city_comment_likes AS (
    SELECT
        p.location_city_id AS city_id,
        COUNT(plc.person_id) AS like_count
    FROM person_likes_comment plc
    JOIN comment c ON plc.comment_id = c.id
    JOIN person p ON c.creator_person_id = p.id
    JOIN place pl ON p.location_city_id = pl.id
    GROUP BY p.location_city_id
),
city_tags AS (
    SELECT
        p.location_city_id AS city_id,
        COUNT(DISTINCT pht.tag_id) AS distinct_tag_count
    FROM person_has_interest_tag pht
    JOIN person p ON pht.person_id = p.id
    JOIN place pl ON p.location_city_id = pl.id
    GROUP BY p.location_city_id
)
SELECT
    cc.city_id,
    cc.city_name,
    cc.comment_count,
    cc.avg_comment_length,
    COALESCE(cl.like_count, 0) AS total_likes,
    COALESCE(ct.distinct_tag_count, 0) AS distinct_interest_tags
FROM city_comments cc
LEFT JOIN city_comment_likes cl ON cc.city_id = cl.city_id
LEFT JOIN city_tags ct ON cc.city_id = ct.city_id
ORDER BY cc.comment_count DESC
LIMIT 10
