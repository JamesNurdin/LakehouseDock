WITH likes_by_tag_country_gender AS (
    SELECT
        cht.tag_id,
        p.name AS country_name,
        per.gender,
        COUNT(*) AS likes_count,
        COUNT(DISTINCT c.id) AS distinct_comments_liked,
        AVG(c.length) AS avg_comment_length
    FROM comment_has_tag_tag AS cht
    JOIN comment AS c
        ON cht.comment_id = c.id
    JOIN person_likes_comment AS plc
        ON plc.comment_id = c.id
    JOIN person AS per
        ON plc.person_id = per.id
    JOIN place AS p
        ON c.location_country_id = p.id
    GROUP BY
        cht.tag_id,
        p.name,
        per.gender
)
SELECT *
FROM likes_by_tag_country_gender
ORDER BY likes_count DESC
LIMIT 50
