WITH comment_likes AS (
    SELECT
        c.id AS comment_id,
        c.creator_person_id,
        cht.tag_id,
        c.length AS comment_length,
        COUNT(pl.person_id) AS like_count
    FROM comment c
    JOIN comment_has_tag_tag cht
        ON cht.comment_id = c.id
    LEFT JOIN person_likes_comment pl
        ON pl.comment_id = c.id
    GROUP BY c.id, c.creator_person_id, cht.tag_id, c.length
)
SELECT
    o.name AS university_name,
    cl.tag_id,
    SUM(cl.like_count) AS total_likes,
    AVG(cl.comment_length) AS avg_comment_length
FROM comment_likes cl
JOIN person p
    ON p.id = cl.creator_person_id
JOIN person_study_at_university psu
    ON psu.person_id = p.id
JOIN organisation o
    ON o.id = psu.university_id
WHERE o.type = 'University'
GROUP BY o.name, cl.tag_id
ORDER BY total_likes DESC
LIMIT 10
