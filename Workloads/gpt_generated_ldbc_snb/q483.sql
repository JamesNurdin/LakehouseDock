WITH comment_tag_data AS (
    SELECT
        c.id AS comment_id,
        t.id AS tag_id,
        t.name AS tag_name,
        pl.id AS country_id,
        pl.name AS country_name,
        c.length AS comment_length,
        p.id AS creator_id,
        CASE WHEN pit.person_id IS NOT NULL THEN 1 ELSE 0 END AS creator_interested_flag
    FROM comment c
    JOIN comment_has_tag_tag cht ON cht.comment_id = c.id
    JOIN tag t ON t.id = cht.tag_id
    JOIN person p ON p.id = c.creator_person_id
    LEFT JOIN person_has_interest_tag pit ON pit.person_id = p.id AND pit.tag_id = t.id
    JOIN place pl ON pl.id = c.location_country_id
)
SELECT
    ct_data.tag_id,
    ct_data.tag_name,
    ct_data.country_id,
    ct_data.country_name,
    COUNT(DISTINCT ct_data.comment_id) AS comment_count,
    SUM(ct_data.comment_length) AS total_comment_length,
    AVG(ct_data.comment_length) AS avg_comment_length,
    COUNT(DISTINCT ct_data.creator_id) AS distinct_creator_count,
    SUM(ct_data.creator_interested_flag) * 1.0 / COUNT(DISTINCT ct_data.comment_id) AS creator_interest_ratio,
    COUNT(plc.person_id) AS total_like_count,
    COUNT(DISTINCT plc.person_id) AS distinct_liker_count
FROM comment_tag_data ct_data
LEFT JOIN person_likes_comment plc ON plc.comment_id = ct_data.comment_id
GROUP BY
    ct_data.tag_id,
    ct_data.tag_name,
    ct_data.country_id,
    ct_data.country_name
ORDER BY comment_count DESC
LIMIT 10
