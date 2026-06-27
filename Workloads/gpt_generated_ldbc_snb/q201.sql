WITH liked_content AS (
    SELECT plp.person_id,
           p.length AS content_length
    FROM person_likes_post plp
    JOIN post p ON plp.post_id = p.id
    UNION ALL
    SELECT plc.person_id,
           c.length AS content_length
    FROM person_likes_comment plc
    JOIN comment c ON plc.comment_id = c.id
)
SELECT per.id,
       per.first_name,
       per.last_name,
       per.gender,
       COUNT(*) AS total_likes,
       SUM(lc.content_length) AS total_content_length,
       CAST(SUM(lc.content_length) AS double) / COUNT(*) AS avg_content_length
FROM liked_content lc
JOIN person per ON lc.person_id = per.id
GROUP BY per.id, per.first_name, per.last_name, per.gender
ORDER BY total_likes DESC
LIMIT 10
