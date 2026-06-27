WITH comment_stats AS (
    SELECT
        c.location_country_id AS country_id,
        COUNT(DISTINCT c.id) AS num_comments,
        COUNT(pl.person_id) AS total_likes,
        AVG(c.length) AS avg_comment_length,
        COUNT(DISTINCT c.creator_person_id) AS unique_commenters
    FROM comment c
    LEFT JOIN person_likes_comment pl ON c.id = pl.comment_id
    GROUP BY c.location_country_id
),
post_stats AS (
    SELECT
        p.location_country_id AS country_id,
        COUNT(DISTINCT p.id) AS num_posts,
        COUNT(DISTINCT p.creator_person_id) AS unique_posters
    FROM post p
    GROUP BY p.location_country_id
)
SELECT
    co.name AS country,
    co.type AS place_type,
    cs.num_comments,
    cs.total_likes,
    cs.avg_comment_length,
    cs.unique_commenters,
    ps.num_posts,
    ps.unique_posters
FROM place co
LEFT JOIN comment_stats cs ON co.id = cs.country_id
LEFT JOIN post_stats ps ON co.id = ps.country_id
WHERE co.type = 'Country'
ORDER BY cs.total_likes DESC
LIMIT 20
