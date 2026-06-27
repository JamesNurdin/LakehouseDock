WITH comment_data AS (
    SELECT
        c.id AS comment_id,
        c.creator_person_id,
        c.length AS comment_length,
        c.parent_comment_id,
        pc.length AS parent_comment_length,
        c.browser_used AS comment_browser_used
    FROM comment c
    LEFT JOIN comment pc
        ON c.parent_comment_id = pc.id
)
SELECT
    p.id AS person_id,
    p.first_name,
    p.last_name,
    p.gender,
    COUNT(cd.comment_id) AS total_comments,
    AVG(cd.comment_length) AS avg_comment_length,
    SUM(CASE WHEN cd.parent_comment_id IS NULL THEN 1 ELSE 0 END) AS top_level_comments,
    SUM(CASE WHEN cd.parent_comment_id IS NOT NULL THEN 1 ELSE 0 END) AS reply_comments,
    AVG(cd.parent_comment_length) AS avg_parent_comment_length
FROM comment_data cd
JOIN person p
    ON cd.creator_person_id = p.id
GROUP BY
    p.id,
    p.first_name,
    p.last_name,
    p.gender
ORDER BY total_comments DESC
LIMIT 10
