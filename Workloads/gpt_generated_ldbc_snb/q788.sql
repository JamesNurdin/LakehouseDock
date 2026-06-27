WITH post_likes AS (
    SELECT
        p.id,
        p.creator_person_id,
        COUNT(plp.person_id) AS like_count
    FROM post p
    LEFT JOIN person_likes_post plp
        ON plp.post_id = p.id
    GROUP BY p.id, p.creator_person_id
)
SELECT
    pl.creator_person_id,
    COUNT(pl.id) AS post_count,
    SUM(pl.like_count) AS total_likes,
    AVG(pl.like_count) AS avg_likes_per_post
FROM post_likes pl
GROUP BY pl.creator_person_id
ORDER BY total_likes DESC
LIMIT 10
