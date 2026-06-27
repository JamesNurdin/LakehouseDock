/*
  Analytical query: For each person compute the number of comments they authored,
  the total length of those comments, and how many likes their comments have received.
  Also calculate the average likes per comment.
*/
WITH comment_stats AS (
    SELECT
        p.id AS person_id,
        p.first_name,
        p.last_name,
        COUNT(c.id) AS comment_count,
        COALESCE(SUM(c.length), 0) AS total_comment_length
    FROM person p
    LEFT JOIN comment c
        ON c.creator_person_id = p.id
    GROUP BY p.id, p.first_name, p.last_name
),
likes_received_stats AS (
    SELECT
        c.creator_person_id AS person_id,
        COUNT(plc.person_id) AS total_likes_received
    FROM comment c
    LEFT JOIN person_likes_comment plc
        ON plc.comment_id = c.id
    GROUP BY c.creator_person_id
)
SELECT
    cs.person_id,
    cs.first_name,
    cs.last_name,
    cs.comment_count,
    cs.total_comment_length,
    COALESCE(lrs.total_likes_received, 0) AS total_likes_received,
    CASE
        WHEN cs.comment_count > 0 THEN COALESCE(lrs.total_likes_received, 0) * 1.0 / cs.comment_count
        ELSE NULL
    END AS avg_likes_per_comment
FROM comment_stats cs
LEFT JOIN likes_received_stats lrs
    ON lrs.person_id = cs.person_id
ORDER BY total_likes_received DESC
LIMIT 100
