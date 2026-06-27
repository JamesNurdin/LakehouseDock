WITH comment_metrics AS (
    SELECT
        c.id AS comment_id,
        c.length,
        c.creator_person_id,
        p.gender,
        COALESCE(l.like_cnt, 0) AS like_cnt
    FROM comment c
    JOIN person p
        ON c.creator_person_id = p.id
    LEFT JOIN (
        SELECT comment_id, COUNT(*) AS like_cnt
        FROM person_likes_comment
        GROUP BY comment_id
    ) l
        ON c.id = l.comment_id
)
SELECT
    ct.tag_id,
    cm.gender,
    COUNT(DISTINCT cm.comment_id) AS num_comments,
    SUM(cm.like_cnt) AS total_likes,
    AVG(cm.length) AS avg_comment_length
FROM comment_has_tag_tag ct
JOIN comment_metrics cm
    ON ct.comment_id = cm.comment_id
GROUP BY ct.tag_id, cm.gender
HAVING COUNT(DISTINCT cm.comment_id) >= 10
ORDER BY total_likes DESC
LIMIT 100
