WITH post_likes AS (
    SELECT
        p.creator_person_id AS creator_person_id,
        COUNT(*) AS post_like_count,
        COUNT(DISTINCT p.id) AS post_count
    FROM post p
    JOIN person_likes_post plp
        ON p.id = plp.post_id
    GROUP BY p.creator_person_id
),
comment_likes AS (
    SELECT
        c.creator_person_id AS creator_person_id,
        COUNT(*) AS comment_like_count,
        COUNT(DISTINCT c.id) AS comment_count
    FROM comment c
    JOIN person_likes_comment plc
        ON c.id = plc.comment_id
    GROUP BY c.creator_person_id
)
SELECT
    per.id AS person_id,
    per.first_name,
    per.last_name,
    COALESCE(pl.post_count, 0) AS post_count,
    COALESCE(pl.post_like_count, 0) AS post_like_count,
    COALESCE(cl.comment_count, 0) AS comment_count,
    COALESCE(cl.comment_like_count, 0) AS comment_like_count,
    COALESCE(pl.post_like_count, 0) + COALESCE(cl.comment_like_count, 0) AS total_likes
FROM person per
LEFT JOIN post_likes pl
    ON per.id = pl.creator_person_id
LEFT JOIN comment_likes cl
    ON per.id = cl.creator_person_id
WHERE per.gender = 'male'
ORDER BY total_likes DESC
LIMIT 10
