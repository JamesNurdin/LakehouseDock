WITH liked_comments AS (
    SELECT
        cht.tag_id,
        plc.person_id AS liker_id,
        c.id AS comment_id
    FROM comment c
    JOIN comment_has_tag_tag cht
        ON cht.comment_id = c.id
    JOIN person_likes_comment plc
        ON plc.comment_id = c.id
    JOIN person p
        ON p.id = plc.person_id
    JOIN person_has_interest_tag pit
        ON pit.person_id = p.id
    WHERE cht.tag_id = pit.tag_id
)
SELECT
    tag_id,
    COUNT(*) AS likes_count
FROM liked_comments
GROUP BY tag_id
HAVING COUNT(*) > 10
ORDER BY likes_count DESC
LIMIT 5
