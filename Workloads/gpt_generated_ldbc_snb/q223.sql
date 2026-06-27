WITH comment_tag_info AS (
    SELECT
        c.id AS comment_id,
        c.length AS comment_length,
        c.location_country_id AS country_id,
        t.id AS tag_id,
        t.name AS tag_name,
        tc.id AS tag_class_id,
        tc.name AS tag_class_name,
        ptc.id AS parent_tag_class_id,
        ptc.name AS parent_tag_class_name
    FROM comment c
    JOIN comment_has_tag_tag cht
        ON cht.comment_id = c.id
    JOIN tag t
        ON t.id = cht.tag_id
    JOIN tag_class tc
        ON tc.id = t.type_tag_class_id
    LEFT JOIN tag_class ptc
        ON ptc.id = tc.subclass_of_tag_class_id
)
SELECT
    p.name AS country_name,
    COALESCE(cti.parent_tag_class_name, cti.tag_class_name) AS top_tag_class_name,
    COUNT(DISTINCT cti.comment_id) AS comment_count,
    AVG(cti.comment_length) AS avg_comment_length,
    COUNT(DISTINCT plc.person_id) AS distinct_likers
FROM comment_tag_info cti
JOIN place p
    ON p.id = cti.country_id
LEFT JOIN person_likes_comment plc
    ON plc.comment_id = cti.comment_id
GROUP BY
    p.name,
    COALESCE(cti.parent_tag_class_name, cti.tag_class_name)
ORDER BY comment_count DESC
LIMIT 20
