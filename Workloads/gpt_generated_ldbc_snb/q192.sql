WITH likes_per_comment AS (
    SELECT
        comment_id,
        COUNT(*) AS like_count
    FROM person_likes_comment
    GROUP BY comment_id
),
comment_tag_likes AS (
    SELECT
        c.id AS comment_id,
        c.creator_person_id,
        c.length,
        c_tag.tag_id,
        COALESCE(lpc.like_count, 0) AS like_count
    FROM comment c
    JOIN comment_has_tag_tag c_tag
        ON c_tag.comment_id = c.id
    LEFT JOIN likes_per_comment lpc
        ON lpc.comment_id = c.id
    JOIN place pl
        ON c.location_country_id = pl.id
    WHERE pl.type = 'Country'
)
SELECT
    p.id AS person_id,
    p.first_name,
    p.last_name,
    COUNT(DISTINCT ct.comment_id) AS comment_count,
    SUM(ct.like_count) AS likes_received,
    COUNT(DISTINCT ct.tag_id) AS distinct_tag_count,
    AVG(ct.length) AS avg_comment_length
FROM comment_tag_likes ct
JOIN person p
    ON p.id = ct.creator_person_id
GROUP BY
    p.id,
    p.first_name,
    p.last_name
ORDER BY likes_received DESC
LIMIT 10
