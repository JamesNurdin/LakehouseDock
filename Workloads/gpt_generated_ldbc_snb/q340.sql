WITH comment_tag_stats AS (
    SELECT
        ct.tag_id,
        COUNT(DISTINCT c.id) AS total_comments,
        AVG(c.length) AS avg_comment_length,
        COUNT(DISTINCT plc.person_id) AS distinct_comment_likers,
        COUNT(DISTINCT plp.person_id) AS distinct_post_likers
    FROM comment_has_tag_tag ct
    JOIN comment c
        ON ct.comment_id = c.id
    LEFT JOIN person_likes_comment plc
        ON plc.comment_id = c.id
    LEFT JOIN post p
        ON c.parent_post_id = p.id
    LEFT JOIN person_likes_post plp
        ON plp.post_id = p.id
    GROUP BY ct.tag_id
)
SELECT
    tag_id,
    total_comments,
    avg_comment_length,
    distinct_comment_likers,
    distinct_post_likers
FROM comment_tag_stats
ORDER BY total_comments DESC
LIMIT 10
