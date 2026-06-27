WITH created_comment_stats AS (
    SELECT
        creator_person_id,
        COUNT(*) AS created_comment_count,
        COUNT(CASE WHEN parent_comment_id IS NOT NULL THEN 1 END) AS created_reply_count,
        AVG(length) AS avg_created_length
    FROM comment
    GROUP BY creator_person_id
),
liked_comment_stats AS (
    SELECT
        plc.person_id,
        COUNT(*) AS liked_comment_count,
        COUNT(CASE WHEN c.parent_comment_id IS NOT NULL THEN 1 END) AS liked_reply_count,
        AVG(c.length) AS avg_liked_length,
        COUNT(CASE WHEN c.creator_person_id = plc.person_id THEN 1 END) AS liked_own_comment_count
    FROM person_likes_comment plc
    JOIN comment c ON plc.comment_id = c.id
    GROUP BY plc.person_id
)
SELECT
    p.id AS person_id,
    p.first_name,
    p.last_name,
    p.gender,
    COALESCE(cc.created_comment_count, 0) AS created_comment_count,
    COALESCE(cc.created_reply_count, 0) AS created_reply_count,
    COALESCE(cc.avg_created_length, 0) AS avg_created_length,
    COALESCE(lc.liked_comment_count, 0) AS liked_comment_count,
    COALESCE(lc.liked_reply_count, 0) AS liked_reply_count,
    COALESCE(lc.avg_liked_length, 0) AS avg_liked_length,
    COALESCE(lc.liked_own_comment_count, 0) AS liked_own_comment_count,
    CASE WHEN COALESCE(cc.created_comment_count, 0) > 0
         THEN COALESCE(lc.liked_comment_count, 0) * 1.0 / cc.created_comment_count
         ELSE NULL
    END AS like_to_create_ratio
FROM person p
LEFT JOIN created_comment_stats cc ON p.id = cc.creator_person_id
LEFT JOIN liked_comment_stats lc ON p.id = lc.person_id
ORDER BY liked_comment_count DESC
LIMIT 50
