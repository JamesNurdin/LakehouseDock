WITH likes_by_tag_country AS (
    SELECT
        p_tag.tag_id,
        country.name AS country_name,
        COUNT(*) AS likes_count,
        COUNT(DISTINCT comment.id) AS distinct_comments_liked,
        AVG(comment.length) AS avg_comment_length
    FROM person AS p
    JOIN person_has_interest_tag AS p_tag
        ON p_tag.person_id = p.id
    JOIN person_likes_comment AS p_like
        ON p_like.person_id = p.id
    JOIN comment
        ON comment.id = p_like.comment_id
    JOIN place AS country
        ON comment.location_country_id = country.id
    GROUP BY p_tag.tag_id, country.name
)
SELECT
    tag_id,
    country_name,
    likes_count,
    distinct_comments_liked,
    avg_comment_length
FROM likes_by_tag_country
ORDER BY likes_count DESC
LIMIT 10
