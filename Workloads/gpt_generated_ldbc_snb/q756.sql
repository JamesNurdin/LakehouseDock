WITH comment_tag_likes AS (
    SELECT
        cht.tag_id,
        c.id AS comment_id,
        c.length AS comment_length,
        c.parent_post_id,
        plc.person_id AS liked_by_person_id,
        p.language AS post_language
    FROM comment AS c
    JOIN comment_has_tag_tag AS cht
        ON cht.comment_id = c.id
    LEFT JOIN person_likes_comment AS plc
        ON plc.comment_id = c.id
    LEFT JOIN post AS p
        ON c.parent_post_id = p.id
)
SELECT
    tag_id,
    post_language,
    COUNT(DISTINCT comment_id) AS num_comments,
    COUNT(liked_by_person_id) AS total_likes,
    AVG(comment_length) AS avg_comment_length,
    COUNT(DISTINCT parent_post_id) AS num_distinct_posts
FROM comment_tag_likes
GROUP BY tag_id, post_language
ORDER BY total_likes DESC
LIMIT 20
