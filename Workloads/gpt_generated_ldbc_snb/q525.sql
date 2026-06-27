WITH forum_member_posts AS (
    SELECT
        fmp.forum_id,
        post.id AS post_id,
        post.length,
        plp.person_id AS liker_id,
        fmp.person_id AS member_id
    FROM forum_has_member_person AS fmp
    JOIN person AS p
        ON fmp.person_id = p.id
    JOIN post
        ON post.creator_person_id = p.id
    LEFT JOIN person_likes_post AS plp
        ON plp.post_id = post.id
)
SELECT
    forum_id,
    COUNT(DISTINCT post_id) AS total_posts,
    COUNT(liker_id) AS total_likes,
    AVG(length) AS avg_post_length,
    COUNT(DISTINCT member_id) AS distinct_members
FROM forum_member_posts
GROUP BY forum_id
ORDER BY total_likes DESC
LIMIT 10
