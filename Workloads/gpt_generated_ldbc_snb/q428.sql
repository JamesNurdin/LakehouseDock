WITH comment_tag_likes AS (
    SELECT
        c.id AS comment_id,
        c.creation_date AS comment_creation_date,
        c.length AS comment_length,
        c.creator_person_id,
        c.location_country_id AS comment_country_id,
        ch.tag_id,
        t.name AS tag_name,
        plc.name AS comment_country_name,
        COUNT(pl.person_id) AS like_count
    FROM comment c
    JOIN comment_has_tag_tag ch
        ON ch.comment_id = c.id
    JOIN tag t
        ON t.id = ch.tag_id
    LEFT JOIN person_likes_comment pl
        ON pl.comment_id = c.id
    LEFT JOIN place plc
        ON plc.id = c.location_country_id
    GROUP BY
        c.id,
        c.creation_date,
        c.length,
        c.creator_person_id,
        c.location_country_id,
        ch.tag_id,
        t.name,
        plc.name
)
SELECT
    tag_id,
    tag_name,
    comment_country_name,
    COUNT(comment_id) AS comment_count,
    SUM(comment_length) AS total_comment_length,
    AVG(comment_length) AS avg_comment_length,
    SUM(like_count) AS total_likes,
    ROUND(AVG(like_count), 2) AS avg_likes_per_comment
FROM comment_tag_likes
GROUP BY
    tag_id,
    tag_name,
    comment_country_name
ORDER BY total_likes DESC
LIMIT 20
