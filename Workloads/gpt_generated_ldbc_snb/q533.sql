-- Tag popularity and engagement by country (place)
-- For each tag and the country where the content was created, compute:
--   * total number of likes on comments and posts with that tag
--   * weighted average length of the content (comments + posts)
--   * total distinct creators (people who authored the liked content)
WITH comment_likes_by_tag_place AS (
    SELECT
        t.id AS tag_id,
        t.name AS tag_name,
        pl.id AS place_id,
        pl.name AS place_name,
        COUNT(plc.person_id) AS likes,
        AVG(c.length) AS avg_length,
        COUNT(DISTINCT c.creator_person_id) AS distinct_creators
    FROM comment_has_tag_tag cht
    JOIN comment c ON cht.comment_id = c.id
    JOIN tag t ON cht.tag_id = t.id
    LEFT JOIN person_likes_comment plc ON plc.comment_id = c.id
    LEFT JOIN place pl ON c.location_country_id = pl.id
    GROUP BY t.id, t.name, pl.id, pl.name
),
post_likes_by_tag_place AS (
    SELECT
        t.id AS tag_id,
        t.name AS tag_name,
        pl.id AS place_id,
        pl.name AS place_name,
        COUNT(plp.person_id) AS likes,
        AVG(p.length) AS avg_length,
        COUNT(DISTINCT p.creator_person_id) AS distinct_creators
    FROM post_has_tag_tag pht
    JOIN post p ON pht.post_id = p.id
    JOIN tag t ON pht.tag_id = t.id
    LEFT JOIN person_likes_post plp ON plp.post_id = p.id
    LEFT JOIN place pl ON p.location_country_id = pl.id
    GROUP BY t.id, t.name, pl.id, pl.name
),
combined AS (
    SELECT * FROM comment_likes_by_tag_place
    UNION ALL
    SELECT * FROM post_likes_by_tag_place
)
SELECT
    tag_id,
    tag_name,
    place_id,
    place_name,
    SUM(likes) AS total_likes,
    SUM(avg_length * likes) / NULLIF(SUM(likes), 0) AS weighted_avg_length,
    SUM(distinct_creators) AS total_distinct_creators
FROM combined
GROUP BY tag_id, tag_name, place_id, place_name
ORDER BY total_likes DESC
LIMIT 50
