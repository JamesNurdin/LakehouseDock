/* Top 10 tags by total likes on comments, with average comment length and comment count per country */
WITH likes_per_comment AS (
    SELECT
        comment_id,
        COUNT(person_id) AS like_count
    FROM person_likes_comment
    GROUP BY comment_id
)
SELECT
    c_tag.tag_id,
    p_country.name AS country_name,
    SUM(COALESCE(l.like_count, 0)) AS total_likes,
    COUNT(DISTINCT c.id) AS total_comments,
    AVG(c.length) AS avg_comment_length
FROM comment_has_tag_tag c_tag
JOIN comment c
    ON c_tag.comment_id = c.id
JOIN place p_country
    ON c.location_country_id = p_country.id
LEFT JOIN likes_per_comment l
    ON l.comment_id = c.id
GROUP BY c_tag.tag_id, p_country.name
ORDER BY total_likes DESC
LIMIT 10
