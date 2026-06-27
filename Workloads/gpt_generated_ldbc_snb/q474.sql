WITH post_tag_likes AS (
    SELECT
        t.id AS tag_id,
        t.name AS tag_name,
        p.id AS post_id,
        COUNT(DISTINCT plp.person_id) AS like_count
    FROM post AS p
    JOIN post_has_tag_tag AS pht
        ON p.id = pht.post_id
    JOIN tag AS t
        ON pht.tag_id = t.id
    LEFT JOIN person_likes_post AS plp
        ON plp.post_id = p.id
    GROUP BY t.id, t.name, p.id
),
tag_aggregates AS (
    SELECT
        tag_id,
        tag_name,
        COUNT(DISTINCT post_id) AS post_count,
        SUM(like_count) AS total_likes,
        AVG(like_count) AS avg_likes_per_post
    FROM post_tag_likes
    GROUP BY tag_id, tag_name
)
SELECT
    tag_id,
    tag_name,
    post_count,
    total_likes,
    avg_likes_per_post
FROM tag_aggregates
ORDER BY total_likes DESC
LIMIT 10
