WITH comment_tag_likes AS (
    SELECT
        c.id AS comment_id,
        c.length AS comment_length,
        cht.tag_id,
        plc.person_id AS liker_person_id,
        p.name AS country_name,
        per.gender AS liker_gender
    FROM comment c
    JOIN comment_has_tag_tag cht
        ON cht.comment_id = c.id
    JOIN person_likes_comment plc
        ON plc.comment_id = c.id
    JOIN person per
        ON plc.person_id = per.id
    JOIN place p
        ON c.location_country_id = p.id
)
SELECT
    ctl.tag_id,
    ctl.country_name,
    ctl.liker_gender,
    COUNT(*) AS total_likes,
    COUNT(DISTINCT ctl.liker_person_id) AS distinct_likers,
    COUNT(DISTINCT ctl.comment_id) AS distinct_comments,
    AVG(ctl.comment_length) AS avg_comment_length
FROM comment_tag_likes ctl
GROUP BY ctl.tag_id, ctl.country_name, ctl.liker_gender
ORDER BY total_likes DESC
LIMIT 30
