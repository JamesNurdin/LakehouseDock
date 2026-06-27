WITH comment_likes AS (
    SELECT 
        c.id AS comment_id,
        c.creator_person_id,
        c.parent_comment_id,
        c.browser_used,
        COUNT(plc.person_id) AS like_count
    FROM comment c
    LEFT JOIN person_likes_comment plc
        ON plc.comment_id = c.id
    GROUP BY c.id, c.creator_person_id, c.parent_comment_id, c.browser_used
),
comment_replies AS (
    SELECT 
        p.id AS parent_comment_id,
        COUNT(c.id) AS reply_count
    FROM comment c
    JOIN comment p
        ON c.parent_comment_id = p.id
    GROUP BY p.id
)
SELECT 
    cl.comment_id,
    cl.creator_person_id,
    cl.browser_used,
    cl.like_count,
    COALESCE(cr.reply_count, 0) AS reply_count,
    CASE 
        WHEN COALESCE(cr.reply_count, 0) = 0 THEN NULL
        ELSE cl.like_count * 1.0 / COALESCE(cr.reply_count, 0)
    END AS likes_per_reply
FROM comment_likes cl
LEFT JOIN comment_replies cr
    ON cl.comment_id = cr.parent_comment_id
ORDER BY cl.like_count DESC
LIMIT 100
