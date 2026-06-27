WITH comment_stats AS (
    SELECT
        c_tag.tag_id AS tag_id,
        COUNT(DISTINCT c.id) AS comment_count,
        AVG(c.length) AS avg_comment_length,
        COUNT(DISTINCT plc.person_id) AS comment_like_count
    FROM comment_has_tag_tag c_tag
    JOIN comment c ON c_tag.comment_id = c.id
    LEFT JOIN person_likes_comment plc ON plc.comment_id = c.id
    GROUP BY c_tag.tag_id
),
post_stats AS (
    SELECT
        p_tag.tag_id AS tag_id,
        COUNT(DISTINCT p.id) AS post_count,
        AVG(p.length) AS avg_post_length,
        COUNT(DISTINCT plp.person_id) AS post_like_count
    FROM post_has_tag_tag p_tag
    JOIN post p ON p_tag.post_id = p.id
    LEFT JOIN person_likes_post plp ON plp.post_id = p.id
    GROUP BY p_tag.tag_id
)
SELECT
    COALESCE(cs.tag_id, ps.tag_id) AS tag_id,
    cs.comment_count,
    cs.avg_comment_length,
    cs.comment_like_count,
    ps.post_count,
    ps.avg_post_length,
    ps.post_like_count,
    (COALESCE(cs.comment_like_count, 0) + COALESCE(ps.post_like_count, 0)) AS total_like_count,
    (COALESCE(cs.comment_count, 0) + COALESCE(ps.post_count, 0)) AS total_content_count
FROM comment_stats cs
FULL OUTER JOIN post_stats ps ON cs.tag_id = ps.tag_id
ORDER BY total_like_count DESC
LIMIT 20
