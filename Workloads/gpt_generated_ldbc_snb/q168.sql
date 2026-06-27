WITH comment_likes AS (
    SELECT
        comment_id,
        COUNT(DISTINCT person_id) AS like_count
    FROM person_likes_comment
    GROUP BY comment_id
)
SELECT
    cht.tag_id,
    pl.id AS place_id,
    pl.name AS place_name,
    COUNT(DISTINCT c.id) AS total_comments,
    SUM(COALESCE(cl.like_count, 0)) AS total_likes,
    AVG(c.length) AS avg_comment_length,
    COUNT(DISTINCT p.id) AS distinct_commenters
FROM comment_has_tag_tag AS cht
JOIN comment AS c
    ON cht.comment_id = c.id
LEFT JOIN comment_likes AS cl
    ON c.id = cl.comment_id
JOIN place AS pl
    ON c.location_country_id = pl.id
JOIN person AS p
    ON c.creator_person_id = p.id
GROUP BY cht.tag_id, pl.id, pl.name
ORDER BY total_likes DESC
LIMIT 100
