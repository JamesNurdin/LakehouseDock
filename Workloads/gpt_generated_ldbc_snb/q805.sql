WITH comment_stats AS (
    SELECT
        c.parent_post_id AS post_id,
        COUNT(*) AS comment_count,
        AVG(c.length) AS avg_comment_length,
        COUNT(CASE WHEN c.parent_comment_id IS NULL THEN 1 END) AS top_level_comment_count,
        COUNT(CASE WHEN c.parent_comment_id IS NOT NULL THEN 1 END) AS reply_comment_count
    FROM comment c
    GROUP BY c.parent_post_id
),
comment_likes_stats AS (
    SELECT
        c.parent_post_id AS post_id,
        COUNT(plc.person_id) AS total_comment_likes,
        COUNT(DISTINCT plc.person_id) AS distinct_like_persons
    FROM comment c
    JOIN person_likes_comment plc
        ON plc.comment_id = c.id
    GROUP BY c.parent_post_id
)
SELECT
    p.id AS post_id,
    p.creation_date AS post_creation_date,
    cs.comment_count,
    cs.avg_comment_length,
    cs.top_level_comment_count,
    cs.reply_comment_count,
    COALESCE(cl.total_comment_likes, 0) AS total_comment_likes,
    COALESCE(cl.distinct_like_persons, 0) AS distinct_like_persons,
    CASE
        WHEN cs.comment_count > 0 THEN COALESCE(cl.total_comment_likes, 0) * 1.0 / cs.comment_count
        ELSE 0
    END AS avg_likes_per_comment
FROM post p
LEFT JOIN comment_stats cs
    ON cs.post_id = p.id
LEFT JOIN comment_likes_stats cl
    ON cl.post_id = p.id
ORDER BY COALESCE(cl.total_comment_likes, 0) DESC
LIMIT 100
