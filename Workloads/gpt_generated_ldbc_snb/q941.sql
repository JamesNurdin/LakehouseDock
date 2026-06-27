WITH comment_tag_likes AS (
    SELECT
        ctag.tag_id,
        c.id AS comment_id,
        c.length,
        c.location_country_id,
        c.creator_person_id,
        COUNT(plc.person_id) AS like_count
    FROM comment_has_tag_tag ctag
    JOIN comment c
        ON ctag.comment_id = c.id
    LEFT JOIN person_likes_comment plc
        ON plc.comment_id = c.id
    GROUP BY ctag.tag_id, c.id, c.length, c.location_country_id, c.creator_person_id
)
SELECT
    ctl.tag_id,
    org.name AS university_name,
    plc_country.name AS country_name,
    COUNT(DISTINCT ctl.comment_id) AS comment_count,
    SUM(ctl.like_count) AS total_likes,
    AVG(ctl.length) AS avg_comment_length
FROM comment_tag_likes ctl
JOIN person p_creator
    ON ctl.creator_person_id = p_creator.id
JOIN person_study_at_university stu
    ON stu.person_id = p_creator.id
JOIN organisation org
    ON stu.university_id = org.id
JOIN place plc_country
    ON ctl.location_country_id = plc_country.id
WHERE org.type = 'University'
GROUP BY ctl.tag_id, org.name, plc_country.name
ORDER BY total_likes DESC
LIMIT 100
