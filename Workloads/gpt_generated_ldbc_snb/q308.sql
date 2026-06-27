WITH comment_tag_likes AS (
    SELECT
        cht.tag_id,
        c.id AS comment_id,
        c.creator_person_id,
        c.length AS comment_length,
        c.location_country_id AS comment_country_id,
        p_country.name AS comment_country_name,
        p_region.id AS comment_region_id,
        p_region.name AS comment_region_name,
        COUNT(plc.person_id) AS like_count
    FROM comment_has_tag_tag cht
    JOIN comment c
        ON cht.comment_id = c.id
    LEFT JOIN person_likes_comment plc
        ON plc.comment_id = c.id
    LEFT JOIN place p_country
        ON c.location_country_id = p_country.id
    LEFT JOIN place p_region
        ON p_country.part_of_place_id = p_region.id
    GROUP BY
        cht.tag_id,
        c.id,
        c.creator_person_id,
        c.length,
        c.location_country_id,
        p_country.name,
        p_country.part_of_place_id,
        p_region.id,
        p_region.name
)

SELECT
    tag_id,
    comment_country_name,
    comment_region_name,
    SUM(like_count) AS total_likes,
    COUNT(DISTINCT comment_id) AS comment_count,
    AVG(comment_length) AS avg_comment_length,
    COUNT(DISTINCT creator_person_id) AS distinct_authors
FROM comment_tag_likes
GROUP BY
    tag_id,
    comment_country_name,
    comment_region_name
ORDER BY total_likes DESC
LIMIT 20
