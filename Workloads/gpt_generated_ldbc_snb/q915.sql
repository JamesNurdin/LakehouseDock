WITH base AS (
    SELECT
        c.id AS comment_id,
        c.length AS comment_length,
        c.creator_person_id AS person_id,
        c.location_country_id AS country_id,
        cht.tag_id,
        pl_city.id AS city_id,
        pl_city.name AS city_name,
        pl_country.name AS country_name
    FROM comment c
    JOIN comment_has_tag_tag cht
        ON cht.comment_id = c.id
    JOIN person p
        ON c.creator_person_id = p.id
    JOIN place pl_city
        ON p.location_city_id = pl_city.id
    JOIN place pl_country
        ON c.location_country_id = pl_country.id
),
replies AS (
    SELECT
        parent.id AS parent_comment_id,
        COUNT(child.id) AS reply_count
    FROM comment parent
    JOIN comment child
        ON child.parent_comment_id = parent.id
    GROUP BY parent.id
)
SELECT
    b.city_name,
    b.country_name,
    b.tag_id,
    COUNT(DISTINCT b.comment_id) AS comment_count,
    AVG(b.comment_length) AS avg_comment_length,
    SUM(COALESCE(r.reply_count, 0)) AS total_replies
FROM base b
LEFT JOIN replies r
    ON r.parent_comment_id = b.comment_id
GROUP BY b.city_name, b.country_name, b.tag_id
ORDER BY comment_count DESC
LIMIT 10
