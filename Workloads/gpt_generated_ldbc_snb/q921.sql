WITH likes_per_person AS (
    SELECT
        plc.person_id,
        COUNT(plc.comment_id) AS liked_comments,
        MIN(plc.creation_date) AS first_like_date,
        MAX(plc.creation_date) AS last_like_date
    FROM person_likes_comment AS plc
    GROUP BY plc.person_id
)
SELECT
    p.id,
    p.first_name,
    p.last_name,
    p.gender,
    p.language,
    lpp.liked_comments,
    lpp.first_like_date,
    lpp.last_like_date,
    RANK() OVER (ORDER BY lpp.liked_comments DESC) AS like_rank
FROM likes_per_person AS lpp
JOIN person AS p
    ON lpp.person_id = p.id
ORDER BY lpp.liked_comments DESC
LIMIT 10
