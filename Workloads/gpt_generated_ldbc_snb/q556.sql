WITH likes_info AS (
    SELECT
        plp.person_id,
        p.id AS post_id,
        p.length AS post_length,
        pt.tag_id,
        pc.id AS country_id,
        pc.name AS country_name,
        per.gender
    FROM person_likes_post plp
    JOIN post p
        ON plp.post_id = p.id
    JOIN post_has_tag_tag pt
        ON p.id = pt.post_id
    JOIN place pc
        ON p.location_country_id = pc.id
    JOIN person per
        ON plp.person_id = per.id
)
SELECT
    tag_id,
    country_name,
    gender,
    COUNT(*) AS total_likes,
    COUNT(DISTINCT person_id) AS distinct_likers,
    AVG(post_length) AS avg_post_length
FROM likes_info
GROUP BY tag_id, country_name, gender
ORDER BY total_likes DESC
LIMIT 200
