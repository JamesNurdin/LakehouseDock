WITH forum_stats AS (
    SELECT
        f.id AS forum_id,
        f.title AS forum_title,
        COUNT(DISTINCT p.id) AS num_posts,
        COUNT(plp.person_id) AS total_post_likes,
        COUNT(DISTINCT plp.person_id) AS distinct_likers,
        COUNT(DISTINCT pwc.company_id) AS distinct_liker_companies,
        AVG(p.length) AS avg_post_length,
        CASE
            WHEN COUNT(DISTINCT p.id) > 0
            THEN COUNT(plp.person_id) * 1.0 / COUNT(DISTINCT p.id)
            ELSE 0
        END AS avg_likes_per_post
    FROM forum f
    LEFT JOIN post p
        ON p.container_forum_id = f.id
    LEFT JOIN person_likes_post plp
        ON plp.post_id = p.id
    LEFT JOIN person liker
        ON liker.id = plp.person_id
    LEFT JOIN person_work_at_company pwc
        ON pwc.person_id = liker.id
    GROUP BY f.id, f.title
)
SELECT
    forum_id,
    forum_title,
    num_posts,
    total_post_likes,
    distinct_likers,
    distinct_liker_companies,
    avg_post_length,
    avg_likes_per_post
FROM forum_stats
ORDER BY total_post_likes DESC
LIMIT 10
