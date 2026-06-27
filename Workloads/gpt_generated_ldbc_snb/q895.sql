-- Top tags by total likes per country
WITH tag_country_likes AS (
    SELECT
        t.id AS tag_id,
        t.name AS tag_name,
        pl.id AS country_id,
        pl.name AS country_name,
        COUNT(plp.person_id) AS total_likes,
        COUNT(DISTINCT plp.person_id) AS distinct_likers,
        AVG(p.length) AS avg_post_length
    FROM tag t
    JOIN post_has_tag_tag pht
        ON pht.tag_id = t.id
    JOIN post p
        ON p.id = pht.post_id
    JOIN place pl
        ON pl.id = p.location_country_id
    LEFT JOIN person_likes_post plp
        ON plp.post_id = p.id
    GROUP BY t.id, t.name, pl.id, pl.name
)
SELECT
    tag_id,
    tag_name,
    country_id,
    country_name,
    total_likes,
    distinct_likers,
    avg_post_length
FROM tag_country_likes
ORDER BY total_likes DESC
LIMIT 20
