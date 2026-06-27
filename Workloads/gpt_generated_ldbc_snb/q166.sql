WITH comment_tag_likes AS (
    SELECT
        c.id AS comment_id,
        c.length AS comment_length,
        c.creator_person_id,
        t.id AS tag_id,
        t.name AS tag_name,
        p.name AS country_name,
        plc.person_id AS liked_by_person_id
    FROM comment c
    JOIN comment_has_tag_tag cht
        ON cht.comment_id = c.id
    JOIN tag t
        ON t.id = cht.tag_id
    LEFT JOIN person_likes_comment plc
        ON plc.comment_id = c.id
    LEFT JOIN place p
        ON p.id = c.location_country_id
)
SELECT
    tag_id,
    tag_name,
    country_name,
    COUNT(DISTINCT comment_id) AS num_comments,
    COUNT(liked_by_person_id) AS total_likes,
    AVG(comment_length) AS avg_comment_length,
    COUNT(DISTINCT creator_person_id) AS distinct_commenters
FROM comment_tag_likes
GROUP BY tag_id, tag_name, country_name
ORDER BY total_likes DESC
LIMIT 20
