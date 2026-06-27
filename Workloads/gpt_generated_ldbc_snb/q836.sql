WITH likes AS (
    SELECT comment_id,
           COUNT(*) AS like_count
    FROM person_likes_comment
    GROUP BY comment_id
),
replies AS (
    SELECT parent_comment_id,
           COUNT(*) AS reply_count,
           AVG(length) AS avg_reply_length
    FROM comment
    WHERE parent_comment_id IS NOT NULL
    GROUP BY parent_comment_id
)
SELECT
    c.id,
    c.creation_date,
    c.creator_person_id,
    COALESCE(l.like_count, 0) AS like_count,
    COALESCE(r.reply_count, 0) AS reply_count,
    r.avg_reply_length
FROM comment c
LEFT JOIN likes l
    ON c.id = l.comment_id
LEFT JOIN replies r
    ON c.id = r.parent_comment_id
ORDER BY like_count DESC, reply_count DESC
LIMIT 100
