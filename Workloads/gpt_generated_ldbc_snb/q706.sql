-- Top 5 tags associated with posts liked by male users located in the United States
WITH liked_posts AS (
    SELECT
        plp.person_id,
        plp.post_id,
        p.length,
        p.location_country_id
    FROM person_likes_post plp
    JOIN person per ON plp.person_id = per.id
    JOIN post p ON plp.post_id = p.id
    WHERE per.gender = 'male'
)
SELECT
    t.id   AS tag_id,
    t.name AS tag_name,
    COUNT(*)                AS total_likes,
    COUNT(DISTINCT lp.post_id) AS distinct_posts,
    AVG(lp.length)          AS avg_post_length
FROM liked_posts lp
JOIN post_has_tag_tag pht ON lp.post_id = pht.post_id
JOIN tag t               ON pht.tag_id = t.id
JOIN place pl            ON lp.location_country_id = pl.id
WHERE pl.name = 'United States'
GROUP BY t.id, t.name
ORDER BY total_likes DESC
LIMIT 5
