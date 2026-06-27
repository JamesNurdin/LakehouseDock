WITH likes_by_tag_country AS (
    SELECT
        pht.tag_id,
        pl.name AS country_name,
        COUNT(*) AS total_likes,
        COUNT(DISTINCT plp.post_id) AS distinct_posts,
        AVG(p.length) AS avg_post_length,
        COUNT(DISTINCT plp.person_id) AS distinct_users
    FROM person_likes_post plp
    JOIN post p ON plp.post_id = p.id
    JOIN post_has_tag_tag pht ON p.id = pht.post_id
    JOIN place pl ON p.location_country_id = pl.id
    GROUP BY pht.tag_id, pl.name, pl.id
)
SELECT
    tag_id,
    country_name,
    total_likes,
    distinct_posts,
    avg_post_length,
    distinct_users,
    RANK() OVER (PARTITION BY tag_id ORDER BY total_likes DESC) AS country_rank_for_tag
FROM likes_by_tag_country
ORDER BY total_likes DESC
LIMIT 100
