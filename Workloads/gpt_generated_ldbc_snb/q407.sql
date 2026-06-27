WITH comment_likes AS (
    SELECT
        c.id AS comment_id,
        c.creator_person_id AS creator_id,
        c.length AS comment_length,
        c.location_country_id AS country_id,
        COUNT(plc.person_id) AS like_count,
        COUNT(DISTINCT plc.person_id) AS distinct_liker_count
    FROM comment c
    LEFT JOIN person_likes_comment plc
        ON plc.comment_id = c.id
    GROUP BY c.id, c.creator_person_id, c.length, c.location_country_id
)
SELECT
    t.id AS tag_id,
    t.name AS tag_name,
    pl.id AS country_id,
    pl.name AS country_name,
    COUNT(DISTINCT cl.comment_id) AS comment_count,
    SUM(cl.like_count) AS total_likes,
    AVG(cl.comment_length) AS avg_comment_length,
    COUNT(DISTINCT cl.creator_id) AS distinct_commenters
FROM comment_has_tag_tag c_ht
JOIN comment_likes cl
    ON c_ht.comment_id = cl.comment_id
JOIN tag t
    ON c_ht.tag_id = t.id
JOIN place pl
    ON cl.country_id = pl.id
GROUP BY t.id, t.name, pl.id, pl.name
ORDER BY total_likes DESC
LIMIT 50
